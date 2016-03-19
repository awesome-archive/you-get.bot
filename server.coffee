# Main server that listens to GitHub webhook events.

crypto = require 'crypto'
http = require 'http'
util = require 'util'
StringDecoder = require('string_decoder').StringDecoder
decoder = new StringDecoder('utf8')

# Get default port from command-line argument
port = process.argv.slice(2)[0]

# Get tokens from environment variables
githubToken = process.env.GITHUB_OAUTH_TOKEN
secretToken = process.env.WEBHOOK_SECRET_TOKEN

client = require './client'
i18n = require './i18n'

# Handler for webhook events
ping = require './replyPing'
issues = require './replyIssues'
pullRequest = require './replyPullRequest'
mainHandler = (event, payload) ->
  switch event
    when 'ping' then ping.handle payload
    when 'issues' then issues.handle payload
    when 'pull_request' then pullRequest.handle payload
    # TODO: more events

class WebhookListener
  @maxDataSize: 1e7 # maximum size of POST data ~10MB

  @verify: (signature, text) ->
    bs = new Buffer text.toString 'ascii'
    signature == 'sha1=' +
      crypto.createHmac('sha1', secretToken).update(bs).digest('hex')

  constructor: (@port) ->

  handleRequest: (request, response) ->
    if request.method == 'POST'
      if request.url == '/payload'
        body = ''

        request.on 'data', (data) ->
          body += data

          # too much POST data, kill the connection
          if body.length > @maxDataSize
            console.log 'Maximum size of POST data exceeded'
            request.connection.destroy()

        request.on 'end', () ->
          payload = JSON.parse body

          # validate payloads from GitHub
          if WebhookListener.verify request.headers['x-hub-signature'], body
            mainHandler request.headers['x-github-event'], payload
            response.end 'OK'
          else
            # 500 Bad signature
            console.log 'Bad signature from request: '
            console.log request.headers
            response.statusCode = 500
            response.end 'Bad signature'

do ->
  if !secretToken
    # error
    console.log 'WEBHOOK_SECRET_TOKEN not set'
    return

  if !githubToken
    # error
    console.log 'GITHUB_OAUTH_TOKEN not set'
    return

  if !port or isNaN port
    # test client
    # /rate_limit does not consume any of remaining quota
    client.rateLimit (data) ->
      console.log "<< API rate: #{JSON.stringify data.rate}"
    return

  # start server
  listener = new WebhookListener port
  server = http.createServer listener.handleRequest
  server.listen listener.port, () ->
    console.log "Bot server listening on: http://localhost:%s", listener.port
