fs = require 'fs'

module.exports = haveFilesChanged = (glob, callback) ->
  # todo: implementation

if process.argv[1] == __filename

  assert = require 'assert'

  touch = (filename) -> fs.writeFileSync filename, ''

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

      # let's change something!
      touch '/tmp/foo.txt'

      haveFilesChanged '/tmp/*.txt'
        yes: -> yesCallCount++ ; cb()
        no:  -> noCallCount++  ; cb()

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
