
tester = require './tester'

Release =
  handle: (payload) ->
    action = payload.action
    tagName = payload.release.tag_name
    console.log '>> %s is published', tagName
    tester.updateStable() # upgrade you-get (latest release)

module.exports = Release
