fs = require "fs"
less = require "less"

{Compiler} = require "./base"


class exports.LessCompiler extends Compiler
  patterns: -> [/\.less$/]

  compile: (files, callback) ->
    mainFilePath = @getAppPath "src/app/styles/main.less"

    fs.readFile mainFilePath, "utf8", (error, data) =>
      if error?
        return @logerror "#{error.message} in #{error.filename}"
      parser = new less.Parser
        paths: [@getAppPath "src/app/styles/"]
        filename: mainFilePath

      parser.parse data, (error, tree) =>
        return @logError error if error?
        css = tree.toCSS(compress: true)
        main = @getBuildPath "web/css/main.css"
        fs.writeFile main, css, "utf8", (error) =>
          return @logError error if error?
          @log()
          callback @getClassName()
