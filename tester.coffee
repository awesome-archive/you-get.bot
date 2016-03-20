# Sandboxed you-get runner.

fs = require 'fs'
spawn = require('child_process').spawn

command = 'you-get'
pypiPackage = process.env.PYPI_PACKAGE ? 'you-get'
upstreamUrl = process.env.UPSTREAM_URL ? 'https://github.com/soimort/you-get'

Tester =
  # Run the latest release of you-get on url
  runStable: (url, out) ->
    proc = spawn command, ['-di', url]
    proc.stdout.on 'data', (chunk) ->
      out chunk.toString 'utf8'
    proc.stderr.on 'data', (chunk) ->
      err chunk.toString 'utf8'

  # Run the current develop branch of you-get on url
  runDevelop: (url, out, err) ->
    proc = spawn "./#{pypiPackage}/#{command}", ['-di', url]
    proc.stdout.on 'data', (chunk) ->
      out chunk.toString 'utf8'
    proc.stderr.on 'data', (chunk) ->
      err chunk.toString 'utf8'

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
      callback chunk.toString 'utf8'

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

module.exports = Tester
