fs = require "fs"
less = require "less"

{Compiler} = require "./base"


class exports.LessCompiler extends Compiler
  patterns: -> [/\.less$/]

  compile: (files, callback) ->
    mainFilePath = @getAppPath "src/app/styles/main.less"

    fs.readFile mainFilePath, "utf8", (error, data) =>
      return @logError error if error?
      parser = new less.Parser
        paths: [@getAppPath "src/app/styles/"]
        filename: mainFilePath

      parser.parse data, (error, tree) =>
        if error?
          return @logError "#{error.message} in #{error.filename}"
        css = tree.toCSS(compress: true)
        main = @getBuildPath "web/css/main.css"
        fs.writeFile main, css, "utf8", (error) =>
          return @logError error if error?
          @log()
          callback @getClassName()
