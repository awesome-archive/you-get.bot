
client = require './client'
i18n = require './i18n'

# Signature to use when posting comments
signature =
  en: "\nYours harmlessly\nMort the Bot"
  zh: "\n——人畜无害的机器人Mort"

Issues =
  onOpened: (issue) ->
    # close issues that are just too short
    if !issue.body or issue.body.length < 15
      user = issue.user.login
      userLang = i18n.detectLang issue.title
      i18n.translate userLang, {
        en: """
        Hello @#{user},
        Please tell us a little more about your issue; we can't deal with it \
        if we don't have any details to look at. :confused:
        Thanks.
        #{signature.en}"""
        zh: """
        @#{user} 您好，
        请更加详细地叙述您的问题所在。对于问题描述过于简短的 issue，我们将无法\
        予以解决。:confused:
        谢谢合作。
        #{signature.zh}"""
        }, (text) ->
        client.createComment issue.number, body: text
        client.closeIssue issue.number

  handle: (payload) ->
    action = payload.action
    issue = payload.issue
    console.log '>> %s %s new issue #%s: %s',
      issue.user.login, action, issue.number, issue.title

    switch action
      when 'opened' then @onOpened issue
      # TODO: more actions

module.exports = Issues
