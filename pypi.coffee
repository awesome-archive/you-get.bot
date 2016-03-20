# Simple wrapper library of PyPIJSON API.
# See: <https://wiki.python.org/moin/PyPIJSON>

https = require 'https'

pypiPackage = process.env.PYPI_PACKAGE ? 'you-get'
userAgent = process.env.USER_AGENT ? 'you-get.bot'

PyPI =
  get: (host, path, callback) ->
    options =
      host: host
      port: 443
      method: 'GET'
      path: path
      headers:
        'Cache-Control' : 'max-age=0'
        'User-Agent'    : userAgent

    req = https.request options, (res) ->
      s = ''
      res.on 'data', (chunk) -> s += chunk
      res.on 'end', -> callback s
    req.end()

  pypiGet: (apiPath, callback) ->
    @get 'pypi.python.org', apiPath, (res) ->
      resData = JSON.parse res
      console.log "GET #{apiPath}"
      callback resData

  latest: (callback) ->
    @pypiGet "/pypi/#{pypiPackage}/json", (resData) ->
      callback resData

module.exports = PyPI
