
client = require './client'
tester = require './tester'

IssueComment =
  onCreated: (issue, comment) ->
    user = comment.user.login

    for line in comment.body.split '\n'
      handleMatches = line.match /@soimort-bot/
      testMatches = line.match /(test|try|试)/i
      linkMatches = line.match /(https?:\/\/[^\ ,]+)/
      developMatches = line.match /develop/
      stableMatches = line.match /(stable|master)/
      if handleMatches? and testMatches? and linkMatches?
        url = linkMatches[1]

        # let's try it (using the latest release)
        if stableMatches?
          console.log '## %s', "testing you-get #{url} (on master)"
          tester.getPythonVersion (pyvers) ->
            tester.getGeoIP (geoip) ->
              tester.runStable url,
                (out) ->
                  return if not out? or out.length <= 2
                  client.createComment issue.number, body: """
                  Hi @#{user}, it works! :yum:
                  ![](https://badge.fury.io/py/you-get.png)

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
                  client.createComment issue.number, body: """
                  Nope, it seems not working for me :confounded:
                  ![](https://badge.fury.io/py/you-get.png)

                  ```
                  $ you-get -di #{url}
                  #{err}
                  ```

                  Python version: `#{pyvers}`
                  GeoIP location: **#{geoip}**
                  Timestamp: *#{new Date().toISOString()}*
                  """

        # let's try it (using the current develop branch)
        if developMatches? or not stableMatches?
          console.log '## %s', "testing you-get #{url} (on develop)"
          tester.getDevelopHead (head) ->
            tester.getPythonVersion (pyvers) ->
              tester.getGeoIP (geoip) ->
                tester.runDevelop url,
                  (out) ->
                    return if not out? or out.length <= 2
                    client.createComment issue.number, body: """
                    Hi @#{user}, it works! :yum: \
                    (`you-get=soimort:develop` #{head})

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
                    client.createComment issue.number, body: """
                    Nope, it seems not working for me :confounded: \
                    (`you-get=soimort:develop` #{head})

                    ```
                    $ you-get -di #{url}
                    #{err}
                    ```

                    Python version: `#{pyvers}`
                    GeoIP location: **#{geoip}**
                    Timestamp: *#{new Date().toISOString()}*
                    """

  handle: (payload) ->
    action = payload.action
    issue = payload.issue
    comment = payload.comment
    console.log '>> %s commented on #%s: %s',
      comment.user.login, issue.number, issue.title

    switch action
      when 'created' then @onCreated issue, comment

module.exports = IssueComment
