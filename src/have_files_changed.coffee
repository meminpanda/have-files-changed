# haveFilesChanged
#
# This module will check if the mtime on a list of files and, when called, a
# 'yes' callback if the files have changed since they were last checked, or a
# 'no' callback if they are the same. The list of files is specified as a glob
# pattern (see https://github.com/isaacs/node-glob).
#
# For example
#
#     haveFilesChanged 'sass/*.sass',
#       yes: filesHaveChangedCallback
#       no: filesHaveNotChangedCallback
#       error: (err) -> throw err
#
# The first time you call `haveFilesChanged`, the yes callback will be fired.
#

fs     = require 'fs'
crypto = require 'crypto'
glob   = require 'glob'
async  = require 'async'

globHashses = {}

module.exports =
haveFilesChanged = (filesGlob, {yes:changeCallback, no:noChangeCallback, error:errorCallback}) ->

  # Get a list of files
  glob filesGlob, (err, files) ->
    return errorCallback err if err?

    # Map the list of files to a list of strings
    async.map files, createStatMap, (err, filenamesWithMtimes) ->
      return errorCallback err if err?

      filenamesWithMtimes = filenamesWithMtimes.sort().join '\n'
      hash = crypto.createHash('sha1').update(filenamesWithMtimes).digest 'hex'

      if hash is globHashses[filesGlob]
        noChangeCallback()
      else
        globHashses[filesGlob] = hash
        changeCallback()

# Returns full path concatenated with mtime formatted in milliseconds since
# epoch. E.g. `/tmp/foo.txt 1344358415000`
createStatMap = (file, cb) ->
  fs.stat file, (err, stats) ->
    return cb err if err?
    cb noErr, "#{file} #{stats.mtime.getTime()}"

noErr = null

# Test

if process.argv[1] == __filename

  assert = require 'assert'

  touch = (filename) -> fs.writeFileSync filename, Date.now()

  touch '/tmp/foo.txt'
  touch '/tmp/bar.txt'
  touch '/tmp/baz.jpg'

  yesCallCount = 0
  noCallCount  = 0

  async.series [

    (cb) ->

      haveFilesChanged '/tmp/*.txt'
        yes: -> yesCallCount++ ; cb()
        no:  -> noCallCount++  ; cb()

    (cb) ->

      # `yes` callback always called the first time
      assert yesCallCount is 1 and noCallCount is 0

      haveFilesChanged '/tmp/*.txt'
        yes: -> yesCallCount++ ; cb()
        no:  -> noCallCount++  ; cb()

    (cb) ->
      # nothing changed so `no` is called
      assert yesCallCount is 1 and noCallCount is 1

      # The filesystem only has second accuracy, so wait for 1 second to run
      # this test
      setTimeout ->

        # let's change something!
        touch '/tmp/foo.txt'

        haveFilesChanged '/tmp/*.txt'
          yes: -> yesCallCount++ ; cb()
          no:  -> noCallCount++  ; cb()

      , 1000

    (cb) ->

      # `yes` callback was called
      assert yesCallCount is 2 and noCallCount is 1

      # finally let's change something *not* in the glob
      touch '/tmp/baz.jpg'

      haveFilesChanged '/tmp/*.txt'
        yes: -> yesCallCount++ ; cb()
        no:  -> noCallCount++  ; cb()

    (cb) ->

      # `no` callback was called
      assert yesCallCount is 2 and noCallCount is 2
      console.log 'ok'

  ]
