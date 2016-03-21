
tester = require './tester'

Push =
  handle: (payload) ->
    ref = payload.ref
    console.log '>> %s is pushed to', ref
    if ref == 'refs/heads/develop'
      tester.updateDevelop() # upgrade you-get (current develop branch)

module.exports = Push
