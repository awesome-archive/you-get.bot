
client = require './client'

Ping =
  handle: (payload) ->
    # print some Zen quotes
    console.log payload.zen

module.exports = Ping
