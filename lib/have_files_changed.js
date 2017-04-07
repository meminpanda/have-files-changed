(function() {
  var assert, jsonfile, file, files_, obj, async, createStatMap, crypto, fs, glob, globHashses, haveFilesChanged, noCallCount, noErr, touch, yesCallCount;

  fs = require('fs');

  crypto = require('crypto');
  jsonfile = require('jsonfile');
   
  file = 'hash.json';
  glob = require('glob');

  async = require('async');

  globHashses = {};
  function getFiles (dir, files_){
      files_ = files_ || [];
      var files = fs.readdirSync(dir);
      for (var i in files){
          var name = dir + '/' + files[i];
          if (fs.statSync(name).isDirectory()){
              getFiles(name, files_);
          } else {
              files_.push(name);
          }
      }
      return files_;
  }
  module.exports = haveFilesChanged = function(filesGlob, _arg) {
    var changeCallback, errorCallback, noChangeCallback;
    jsonfile.readFile(file, function(a, obj) {
      if (obj !== undefined) {
        globHashses = obj;
      }
     changeCallback = _arg.yes, noChangeCallback = _arg.no, errorCallback = _arg.error;
      files_ = files_ || [];
      var files = fs.readdirSync(filesGlob);
      for (var i in files){
          var name = filesGlob + '/' + files[i];
          if (fs.statSync(name).isDirectory()){
              getFiles(name, files_);
          } else {
              files_.push(name);
          }
      }
      return async.map(files_, createStatMap, function(err, filenamesWithMtimes) {
        var hash;
        if (err != null) {
          return errorCallback(err);
        }
        filenamesWithMtimes = filenamesWithMtimes.sort().join('\n');
        hash = crypto.createHash('sha1').update(filenamesWithMtimes).digest('hex');
        if (String(hash) === globHashses['src']) {
          return noChangeCallback();
        } else {
          globHashses[filesGlob] = hash;
          jsonfile.writeFile(file, globHashses, function (a) {

          });
          return changeCallback();
        }
      });
    });
  };

  createStatMap = function(file, cb) {
    return fs.stat(file, function(err, stats) {
      if (err != null) {
        return cb(err);
      }
      return cb(noErr, "" + file + " " + (stats.mtime.getTime()));
    });
  };

  noErr = null;

  if (process.argv[1] === __filename) {
    assert = require('assert');
    touch = function(filename) {
      return fs.writeFileSync(filename, Date.now());
    };
    touch('/tmp/foo.txt');
    touch('/tmp/bar.txt');
    touch('/tmp/baz.jpg');
    yesCallCount = 0;
    noCallCount = 0;
    async.series([
      function(cb) {
        return haveFilesChanged('/tmp/*.txt', {
          yes: function() {
            yesCallCount++;
            return cb();
          },
          no: function() {
            noCallCount++;
            return cb();
          }
        });
      }, function(cb) {
        assert(yesCallCount === 1 && noCallCount === 0);
        return haveFilesChanged('/tmp/*.txt', {
          yes: function() {
            yesCallCount++;
            return cb();
          },
          no: function() {
            noCallCount++;
            return cb();
          }
        });
      }, function(cb) {
        assert(yesCallCount === 1 && noCallCount === 1);
        return setTimeout(function() {
          touch('/tmp/foo.txt');
          return haveFilesChanged('/tmp/*.txt', {
            yes: function() {
              yesCallCount++;
              return cb();
            },
            no: function() {
              noCallCount++;
              return cb();
            }
          });
        }, 1000);
      }, function(cb) {
        assert(yesCallCount === 2 && noCallCount === 1);
        touch('/tmp/baz.jpg');
        return haveFilesChanged('/tmp/*.txt', {
          yes: function() {
            yesCallCount++;
            return cb();
          },
          no: function() {
            noCallCount++;
            return cb();
          }
        });
      }, function(cb) {
        assert(yesCallCount === 2 && noCallCount === 2);
        return console.log('ok');
      }
    ]);
  }

}).call(this);