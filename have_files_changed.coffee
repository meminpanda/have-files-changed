fs = require 'fs'
glob = require 'glob'
async = require 'async'

watchedGlobs = {}

module.exports = haveFilesChanged = (filesGlob, {yes:changeCallback, no:noChangeCallback}) ->
  # get a list of files
  glob filesGlob, {} , (er, files) ->
    # Function to grab the stats for each file in the list.
    # returns a string (eventually a hash?) of the filename and
    # its mtime formatted in milliseconds since epoch
    createStatMap = (file, cb) ->
      fs.stat file, (err, stats) ->
        return cb err if err?
        cb noErr, ""+file + " " + (stats.mtime.getTime())

    # Map the list of files to a list of strings
    async.map files,createStatMap, (err,results) ->
      # Then, take the list of strings and reduce them down
      # to one large string.
      hashOfAllFiles = results.reduce (prevValue, currentValue) ->
        prevValue+currentValue
      , ""

      console.log hashOfAllFiles, watchedGlobs[filesGlob]
      if watchedGlobs[filesGlob] == hashOfAllFiles
        noChangeCallback()
      else
        watchedGlobs[filesGlob] = hashOfAllFiles
        changeCallback()



noErr = null


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
      setTimeout () ->
        # nothing changed so `no` is called
        assert yesCallCount is 1 and noCallCount is 1

        # let's change something!
        touch '/tmp/foo.txt'

        haveFilesChanged '/tmp/*.txt'
          yes: -> yesCallCount++ ; cb()
          no:  -> noCallCount++  ; cb()
        # Strangely enough, the filesystem doesn't have the right
        # kind of resolution for this test. Artificial delay makes
        # the tests pass
      , 600

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

  ]
