# # `bundle`
#
# Bundles this project as defined by the Webpack configuration file.

bundleTaskFactory = require './../helpers/bundle-task-factory'
fs                = require 'fs'
gulp              = require('gulp-help')(require 'gulp')
jade              = require 'gulp-jade'
shell             = require 'gulp-shell'




# @param {Object} config - Build configuration object.
# @param {boolean} uglify - Set to `true` to minify Webpack output using
# UglifyJS.
# @param {boolean} watch - Set to `true` to enable Webpack watching.
# @param {Object} flags- Command line options to output using gulp-help.

module.exports = (config, options, flags) ->

  dummyName = 'build:example:[name]'
  dummyDescription = 'Build an individually named example using Webpack.'

  gulp.task dummyName, dummyDescription, ->
    console.error 'You must specify an example.'

  examples = fs.readdirSync process.cwd() + '/example'

  for example in examples

    name = 'build:example:' + example
    dependencies = ['bundle:example:' + example]

    ((ex, n, d)->
      fn = ->
        gulp.src config.path.example.root + '/' + ex + '/*.jade'
        .pipe jade()
        .pipe gulp.dest config.path.target.example + '/' + ex

      gulp.task n, false, ->
        if options.watch
          gulp.watch [
            config.path.example.root + '/**/*.jade'
          ], fn
        fn()
        watch = ' --watch' unless not options.watch
        shell.task(['gulp ' + d + watch + ' &'])()

    )(example, name, dependencies)
