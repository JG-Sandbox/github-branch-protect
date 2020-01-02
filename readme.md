# README

## About

This is a simple Sinatra web service that can be configured to automatically add branch protection to new GitHub repositories for a specified GitHub Organization.

For more on branch protection, see [GitHub Enterprise Server docs](https://help.github.com/en/enterprise/2.19/admin/developer-workflow/configuring-protected-branches-and-required-status-checks) or [GitHub.com docs](https://help.github.com/en/github/administering-a-repository/configuring-protected-branches).

## Requirements

* [ruby](https://www.ruby-lang.org/en/downloads/releases/)
* [bundler](https://bundler.io/)
* a GitHub account
* a GitHub Organization (you can create one for free)

* You need Admin permissions for the Organization that you want to use with this app.

## Setup

1. Install the required ruby version (see Gemfile).

1. Run `bundle install`.

1. Create a new `config.yml` file in the project root that specifies the settings found in `config_sample.yml`.

   *Add relevant configuration settings for your GitHub Auth token, username, org name, and secret!*

1. Start the service by running `ruby app.rb` from the project root.

   *Your service is now live at `localhost:4567`. Note that you will need a public URL to receive GitHub Webhook requests from GitHub.com. For GitHub.com Webhooks in a local environment, consider [ngrok](https://ngrok.com/).*

   *Note: If your app crashes with a message like `…<module:Middleware>': uninitialized constant Faraday::Error::ClientError (NameError) Did you mean?  Faraday::ClientError`, see the Known Issues below for a temporary fix.*

1. [Configure your GitHub Webhook](https://developer.github.com/webhooks/creating/) to connect with your service.

## Production setup

This is a proof-of-concept that only works locally.

## Known Issues

### App crashes when initialized

*due to  `uninitialized constant Faraday::Error::ClientError (NameError)`*

There's an [open issue](https://github.com/octokit/octokit.rb/issues/1155) with the GitHub `octokit` gem that causes this app to crash on load when using a fresh install of the latest `octokit` gem.

**Temporary fix:**

Modify line 14 in `/Users/jqgorelick/.rvm/gems/ruby-2.6.5/gems/octokit-4.14.0/lib/octokit/middleware/follow_redirects.rb` to read:

`    class RedirectLimitReached < Faraday::ClientError`

### Missing error handling

Due to time constraints, we haven't added error handling yet to account for things like permissions errors or changes or availability with the GitHub API.

### No production configuration

We haven't added production configuration yet. This can only be run as a local process.

### Limited configuration capabilities

It would be ideal to separate app logic (in settings) from environment concerns. Perhaps adding a .env file to store secrets so that we can have a clear code path in app.rb and keep Sinatra's config.yml in the repo history.
