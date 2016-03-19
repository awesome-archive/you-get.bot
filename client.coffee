# Simple wrapper library of GitHub API v3.

https = require 'https'

owner = process.env.GITHUB_OWNER ? 'soimort-bot'
repo = process.env.GITHUB_REPO ? 'you-get'
githubToken = process.env.GITHUB_OAUTH_TOKEN
userAgent = process.env.USER_AGENT ? 'you-get.bot'

Client =
  get: (host, path, callback) ->
    options =
      host: host
      port: 443
      method: 'GET'
      path: path
      headers:
        'Cache-Control' : 'max-age=0'
        'User-Agent'    : userAgent
        'Authorization' : "token #{githubToken}"

    req = https.request options, (res) ->
      s = ''
      res.on 'data', (chunk) -> s += chunk
      res.on 'end', -> callback s
    req.end()

  post: (host, path, body, callback) ->
    options =
      host: host
      port: 443
      method: 'POST'
      path: path
      headers:
        'Cache-Control' : 'max-age=0'
        'User-Agent'    : userAgent
        'Authorization' : "token #{githubToken}"

    req = https.request options, (res) ->
      s = ''
      res.on 'data', (chunk) -> s += chunk
      res.on 'end', -> callback s
    req.write(body)
    req.end()

  githubGet: (apiPath, callback) ->
    @get 'api.github.com', apiPath, (res) ->
      resData = JSON.parse res
      console.log "GET #{apiPath}"
      callback resData

  githubPost: (apiPath, reqData, callback) ->
    reqBody = JSON.stringify reqData
    @post 'api.github.com', apiPath, reqBody, (res) ->
      resData = JSON.parse res
      console.log "POST #{apiPath}"
      callback resData

  zen: (callback) ->
    @get 'api.github.com', '/zen', (res) -> # not JSON
      callback res

  meta: (callback) ->
    @githubGet '/meta', (resData) ->
      callback resData

  rateLimit: (callback) ->
    @githubGet "/rate_limit", (resData) ->
      callback resData

  createComment: (number, reqData) ->
    @githubPost "/repos/#{owner}/#{repo}/issues/#{number}/comments",
      reqData, (resData) ->
        console.log "[#{resData.created_at}] %s",
         "new comment posted to ##{number}"

  createIssue: (reqData) ->
    @githubPost "/repos/#{owner}/#{repo}/issues",
      reqData, (resData) ->
        console.log "[#{resData.created_at}] %s",
         "new issue created: ##{resData.number} #{resData.title}"

  editIssue: (number, reqData, callback) ->
    @githubPost "/repos/#{owner}/#{repo}/issues/#{number}",
      reqData, (resData) ->
        callback resData

  closeIssue: (number) ->
    @editIssue number, state: 'closed',
      (resData) ->
        console.log "[#{resData.closed_at}] %s",
          "issue closed: ##{resData.number} #{resData.title}"

  # TODO: more operations

module.exports = Client
