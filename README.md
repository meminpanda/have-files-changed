have-files-changed
----------------

* Sean McCullough <mcculloughsean@gmail.com>
* Myles Byrne <myles@myles.id.au>

This module will check if the mtime on a list of files and, when called, a
`yes` callback if the files have changed since they were last checked, or a
`no` callback if they are the same. The list of files is specified as a glob
pattern (see https://github.com/isaacs/node-glob).

To get going, install with NPM:

`npm install have-files-changed`

For example

````coffeescript
    haveFilesChanged 'sass/*.sass',
      yes: filesHaveChangedCallback
      no: filesHaveNotChangedCallback
      error: (err) -> throw err
````

The first time you call `haveFilesChanged`, the yes callback will be fired.

