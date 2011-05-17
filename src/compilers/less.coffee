fs      = require 'fs'
path    = require 'path'
helpers = require '../helpers'
colors  = require('../../vendor/termcolors').colors
less    = require 'less'

options  = require('../brunch').options
Compiler = require('./index').Compiler

class exports.LessCompiler extends Compiler
  filePattern: ->
    [/\.less$/]

  compile: (files) ->
    main_file_path = path.join(options.brunchPath, 'src/app/styles/main.less')
    fs.readFile(main_file_path, 'utf8', (err, data) =>
      if err?
        helpers.log colors.lred('less err:   ' + err)
      else
        parser = new less.Parser(
          paths: [path.join(options.brunchPath, 'src')],
          filename: main_file_path
        )

        parser.parse data, (err, tree) ->
          if err?
            helpers.log colors.lred('less err:   ' + err)
          else
            css = tree.toCSS({ compress: true })
            fs.writeFile(path.join(options.buildPath, 'web/css/main.css'), css, 'utf8', (err) =>
              if err?
                helpers.log colors.lred('less err:   ' + err)
              else
                helpers.log "less:     #{colors.green('compiled', true)} main.css\n"
            )
    )
