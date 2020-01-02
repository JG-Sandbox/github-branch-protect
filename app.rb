require 'sinatra'
require 'sinatra/config_file'

require 'json'
require 'octokit'

config_file 'config.yml'

# This service only responds to POST requests from a GitHub Webhook payload.
# Basic structure and naming follows the official docs for GitHub Webhooks.
#
# @see https://developer.github.com/webhooks/configuring/
#
post '/payload' do
  request.body.rewind
  payload_body = request.body.read
  verify_signature(payload_body)

  # Filter requests to perform actions in response to the creation of a master branch
  #
  if request.env["HTTP_X_GITHUB_EVENT"] == "create"

    push = JSON.parse(payload_body)
    org = push.dig("organization", "login")
    ref = push.dig("ref")
    ref_type = push.dig("ref_type")
    master_branch = push.dig("master_branch")
    repo_id = push.dig("repository", "id")

    # Configuration options for the "update branch protection" API endpoint.
    #
    # TODO: move these to app settings for improved code portability.
    #
    # @see https://developer.github.com/v3/repos/branches/#update-branch-protection
    #
    protection_options = {
      :required_status_checks => nil,
      :enforce_admins => nil,
      :required_pull_request_reviews => nil,
      :restrictions => nil,
      :required_linear_history => false,
      :allow_force_pushes => false,
      :allow_deletions => false,
    }

    # If event is for the creation of a new "master" branch in our specified organization.
    #
    # Also handles the case where the master branch name is something different than "master".
    #
    if org == settings.github_org && ref_type == "branch" && ref == master_branch
      # if this event is for the creation of a new master branch for this repo
      add_branch_protection(repo_id, ref, protection_options)
      create_gh_issue(repo_id, ref, protection_options)
    end

  end
end

private

# Adds GitHub branch protections to specified branch with the required Accept header to support API Preview Mode.
#
# @see https://developer.github.com/v3/repos/branches/#update-branch-protection
#
def add_branch_protection(repo_id, branch_name, options = {})
  client = Octokit::Client.new(:access_token => settings.github_auth_token)
  client.protect_branch(repo_id, branch_name, options.merge(accept: 'application/vnd.github.luke-cage-preview+json'))
end

# Creates a new Issue in the same repository where branch protection is being added
# 
# TODO: consider making this a callback add_branch_protection to handle errors
#
def create_gh_issue(repo_id, branch_name, options)
  client = Octokit::Client.new(:access_token => settings.github_auth_token)
  client.create_issue(
      repo_id,
      "[bot] Branch Protections Added to #{branch_name} branch",
      "@#{settings.github_user},
      \n\nBranch protections were added to this repository with options:
      \n\n```\n\n" + JSON.pretty_generate(options, {object_nl: "\n"}) + "\n\n```")
end

# Verifies hash signature provided by the GitHub Webhook settings.
# Code copied from GitHub docs for Securing your Webhooks.
#
# @see https://developer.github.com/webhooks/securing/
#
def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), settings.github_secret, payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end
