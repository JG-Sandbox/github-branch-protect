require 'sinatra'
require 'sinatra/config_file'

require 'json'
require 'octokit'

config_file 'config.yml'


post '/payload' do
  request.body.rewind
  payload_body = request.body.read
  verify_signature(payload_body)

  if request.env["HTTP_X_GITHUB_EVENT"] == "create"
  # Only do something when receiving a payload for a repository

    push = JSON.parse(payload_body)
    org = push.dig("organization", "login")
    ref = push.dig("ref")
    ref_type = push.dig("ref_type")
    master_branch = push.dig("master_branch")
    repo_id = push.dig("repository", "id")

    # =================================
    # 
    # These are the options noted in the API docs that are required for the PUT request 
    # for branch protection.
    #
    # If we need to change these settings frequently, move to a config file.
    # 
    # =================================

    protection_options = {
      :required_status_checks => nil,
      :enforce_admins => nil,
      :required_pull_request_reviews => nil,
      :restrictions => nil,
      :required_linear_history => false,
      :allow_force_pushes => false,
      :allow_deletions => false,
    }

    if org == settings.github_org && ref_type == "branch" && ref == master_branch
      # if this event is for the creation of a new master branch for this repo
      add_branch_protection(repo_id, ref, protection_options)
      create_gh_issue(repo_id, ref, protection_options)
    end

  end
end

private

def add_branch_protection(repo_id, branch_name, options = {})
  client = Octokit::Client.new(:access_token => settings.github_auth_token)
  client.protect_branch(repo_id, branch_name, options.merge(accept: 'application/vnd.github.luke-cage-preview+json'))
end

def create_gh_issue(repo_id, branch_name, options)
  client = Octokit::Client.new(:access_token => settings.github_auth_token)
  client.create_issue(
      repo_id,
      "[bot] Branch Protections Added to #{branch_name} branch",
      "@#{settings.github_user},
      \n\nBranch protections were added to this repository with options:
      \n\n```\n\n" + JSON.pretty_generate(options, {object_nl: "\n"}) + "\n\n```")
end

def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), settings.github_secret, payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end
