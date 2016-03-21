
client = require './client'

PullRequest =
  onOpened: (pullRequest) ->
    user = pullRequest.user.login
    return if user == 'soimort-bot' # don't bother myself

    client.createComment pullRequest.number, body: """
    Hello @#{user},
    Thanks for the Pull Request. We :heart: our contributors!
    Please wait for one of our human maintainers to review your patches. \
    This may take a few days to weeks. Also, please understand that although \
    your Pull Request may or may not be eventually merged, we value all \
    contributions equally.

    祝您健康!

    ![](http://thecatapi.com/api/images/get?format=src&type=gif)"""

  handle: (payload) ->
    action = payload.action
    pullRequest = payload.pull_request
    console.log '>> %s %s new pull request #%s: %s',
      pullRequest.user.login, action, pullRequest.number, pullRequest.title

    switch action
      when 'opened' then @onOpened pullRequest
      # TODO: more actions

module.exports = PullRequest
