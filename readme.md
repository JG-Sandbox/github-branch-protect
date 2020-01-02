# WIP 

## Notes

There's a known issue with the GitHub `octokit` gem that causes this app to crash on load.

Line 14 of `/Users/jqgorelick/.rvm/gems/ruby-2.6.5/gems/octokit-4.14.0/lib/octokit/middleware/follow_redirects.rb`should read:

`    class RedirectLimitReached < Faraday::ClientError`

