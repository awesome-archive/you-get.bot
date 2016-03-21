
client = require './client'
pypi = require './pypi'
i18n = require './i18n'
tester = require './tester'

# Signature to use when posting comments
signature =
  en: "\nYours harmlessly\nMort the Bot"
  zh: "\n——人畜无害的机器人Mort"

Issues =
  onOpened: (issue) ->
    user = issue.user.login
    userLang = i18n.detectLang issue.title

    # close issues that are just too short
    if !issue.body or issue.body.length < 15
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

    linkMatches = issue.body.match /https?:\/\//
    if linkMatches?
      # the issue is about a specific link - not a general discussion or alike

      versionMatches = issue.body.match /you-get: version ([\d.]+)/
      urlMatches = issue.body.match /you-get: \['([^']+)'\]/
      if versionMatches? and urlMatches?
        # well-reported debug message

        # let's try it (using the current develop branch)
        url = urlMatches[1]
        console.log '## %s', "testing you-get #{url}"
        tester.runDevelop url,
          (out) ->
            return if not out? or out.length <= 2
            # cannot reproduce
            console.log out
            tester.getDevelopHead (head) ->
              tester.getPythonVersion (pyvers) ->
                tester.getGeoIP (geoip) ->
                  # version check
                  [userMajor, userMinor, userPatch] =
                    (parseInt v for v in versionMatches[1].split '.')
                  pypi.latest (data) ->
                    [a, b, c] =
                      (parseInt v for v in data.info.version.split '.')
                    if userMajor < a or userMinor < b or userPatch < c
                      client.closeIssue issue.number
                      msg = """
                      Hello @#{user},
                      Your `you-get` is at version **#{versionMatches[1]}**, \
                      but our latest release is version **#{data.info.version}**.
                      Please upgrade it first!
                      """
                    else
                      client.tagIssue issue.number, ['invalid']
                      msg = """
                      It works for me. \
                      (`you-get=soimort:develop` #{head})
                      Perhaps a problem with your network?
                      """
                    client.createComment issue.number, body: """
                    #{msg}

                    ```
                    $ you-get -di #{url}
                    #{out}
                    ```

                    Python version: `#{pyvers}`
                    GeoIP location: **#{geoip}**
                    Timestamp: *#{new Date().toISOString()}*
                    """
          ,
          (err) ->
            return if not err? or err.length <= 2
            # can reproduce (possibly a different error though)
            console.log err
            tester.getDevelopHead (head) ->
              tester.getPythonVersion (pyvers) ->
                tester.getGeoIP (geoip) ->
                  client.createComment issue.number, body: """
                  Hey, I got an error too! \
                  (`you-get=soimort:develop` #{head})

                  ```
                  $ you-get -di #{url}
                  #{err}
                  ```

                  Python version: `#{pyvers}`
                  GeoIP location: **#{geoip}**
                  Timestamp: *#{new Date().toISOString()}*
                  """
                  client.tagIssue issue.number, ['confirmed']
      else
        matches = issue.body.match /you-get: don't panic/
        if matches?
          # need debug message
          client.createComment issue.number, body: """
          Hello @#{user},
          Please **rerun the command with `--debug` option**, \
          and report this issue with the full output.
          Thanks.
          #{signature.en}"""
          client.tagIssue issue.number, ['invalid']
        else
          # TBD: feature request?
          # don't know what to do (yet)
    else
      # no link provided - general discussion?
      client.createComment issue.number, body: """
      Hello @#{user},
      Thank you for the report. \
      It seems that you did not provide any sample link in your issue. \
      If you are making a feature request or bug report, \
      it is strongly recommended to include such links \
      so we can dive further into the issue. \
      If it's a general discussion, you may just dismiss this reminder.
      #{signature.en}"""

  handle: (payload) ->
    action = payload.action
    issue = payload.issue
    console.log '>> %s %s issue #%s: %s',
      issue.user.login, action, issue.number, issue.title

    switch action
      when 'opened' then @onOpened issue
      # TODO: more actions

module.exports = Issues
