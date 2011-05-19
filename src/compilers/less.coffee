fs      = require 'fs'
path    = require 'path'
helpers = require '../helpers'
colors  = require('../../vendor/termcolors').colors

Compiler = require('./base').Compiler

class exports.LessCompiler extends Compiler

  filePattern: ->
    [/\.less$/]

  compile: (files) ->
    less = require 'less' # lazy load dependencies

    mainFilePath = path.join(@options.brunchPath, 'src/app/styles/main.less')
    fs.readFile(mainFilePath, 'utf8', (err, data) =>
      if err?
        helpers.log colors.lred('less err:   ' + err)
      else
        parser = new less.Parser(
          paths: [path.join(@options.brunchPath, 'src')],
          filename: mainFilePath
        )

        parser.parse data, (err, tree) ->
          if err?
            helpers.log colors.lred('less err:   ' + err)
          else
            css = tree.toCSS({ compress: true })
            fs.writeFile(path.join(@options.buildPath, 'web/css/main.css'), css, 'utf8', (err) =>
              if err?
                helpers.log colors.lred('less err:   ' + err)
              else
                helpers.log "less:     #{colors.green('compiled', true)} main.css\n"
            )
    )
