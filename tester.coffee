# Sandboxed you-get runner.

fs = require 'fs'
spawn = require('child_process').spawn

command = 'you-get'
pypiPackage = process.env.PYPI_PACKAGE ? 'you-get'
upstreamUrl = process.env.UPSTREAM_URL ? 'https://github.com/soimort/you-get'

Tester =
  # Run the latest release of you-get on url
  runStable: (url, out, err) ->
    proc = spawn command, ['-di', url]
    # collect stdout as a single string
    outStr = ''
    proc.stdout.on 'data', (chunk) ->
      outStr += chunk.toString 'utf8'
    proc.stdout.on 'end', -> out outStr
    # collect stderr as a single string
    errStr = ''
    proc.stderr.on 'data', (chunk) ->
      errStr += chunk.toString 'utf8'
    proc.stderr.on 'end', -> err errStr

  # Run the current develop branch of you-get on url
  runDevelop: (url, out, err) ->
    proc = spawn "./#{pypiPackage}/#{command}", ['-di', url]
    # collect stdout as a single string
    outStr = ''
    proc.stdout.on 'data', (chunk) ->
      outStr += chunk.toString 'utf8'
    proc.stdout.on 'end', -> out outStr
    # collect stderr as a single string
    errStr = ''
    proc.stderr.on 'data', (chunk) ->
      errStr += chunk.toString 'utf8'
    proc.stderr.on 'end', -> err errStr

  # Get the version string of the latest release
  getStableVersion: (callback) ->
    proc = spawn command, ['-V']
    proc.stderr.on 'data', (chunk) ->
      text = chunk.toString 'utf8'
      versionMatches = text.match /you-get: version ([\d.]+)/
      callback versionMatches[1]

  # Get the version string of the current develop branch
  getDevelopVersion: (callback) ->
    proc = spawn "./#{pypiPackage}/#{command}", ['-V']
    proc.stderr.on 'data', (chunk) ->
      text = chunk.toString 'utf8'
      versionMatches = text.match /you-get: version ([\d.]+)/
      vers = (parseInt v for v in versionMatches[1].split '.')

      proc = spawn 'git',
        ['-C', "./#{pypiPackage}", 'rev-list', 'HEAD', '--count']
      proc.stdout.on 'data', (chunk) ->
        headCount = parseInt chunk.toString 'utf8'

        proc = spawn 'git',
          ['-C', "./#{pypiPackage}", 'rev-list', 'origin/master', '--count']
        proc.stdout.on 'data', (chunk) ->
          masterCount = parseInt chunk.toString 'utf8'

          diffCount = headCount - masterCount
          callback "#{vers[0]}.#{vers[1]}.#{vers[2] + diffCount}"

  # Get the HEAD hash of the current develop branch
  getDevelopHead: (callback) ->
    proc = spawn 'git',
      ['-C', "./#{pypiPackage}", 'rev-parse', 'HEAD']
    proc.stdout.on 'data', (chunk) ->
      callback chunk.toString('utf8')[..-2]

  # Update the latest release (via pip)
  updateStable: ->
    console.log '## %s', "updating #{command} (stable)"
    proc = spawn 'pip3', ['install', '--upgrade', '--user', pypiPackage]
    proc.stdout.on 'data', (chunk) ->
      console.log chunk.toString 'utf8'

  # Update the current develop branch (via git)
  updateDevelop: ->
    try
      fs.lstatSync "./#{pypiPackage}" # raise an error if directory not exist
      # do a git pull
      console.log '## %s', "updating #{command} (develop)"
      proc = spawn 'git', ['-C', "./#{pypiPackage}", 'pull']
      proc.stdout.on 'data', (chunk) ->
        console.log chunk.toString 'utf8'
    catch
      # do a git clone
      console.log '## %s', "cloning #{command} (develop)"
      proc = spawn 'git', ['clone', upstreamUrl]
      proc.stdout.on 'data', (chunk) ->
        console.log chunk.toString 'utf8'

  # Get the version string of Python
  getPythonVersion: (callback) ->
    proc = spawn 'python', ['-V']
    proc.stdout.on 'data', (chunk) ->
      data = chunk.toString 'utf8'
      callback data.split(' ')[1][..-2]

  # Get the IP address
  getIP: (callback) ->
    proc = spawn 'dig',
      ['+short', 'myip.opendns.com', '@resolver1.opendns.com']
    proc.stdout.on 'data', (chunk) ->
      callback chunk.toString('utf8')[..-2]

  # Get the GeoIP country information
  getGeoIP: (callback) ->
    @getIP (ip) ->
      proc = spawn 'geoiplookup', [ip]
      proc.stdout.on 'data', (chunk) ->
        data = chunk.toString 'utf8'
        matches = data.match /GeoIP Country Edition: (.+)\n/
        callback matches[1] if matches?

module.exports = Tester
