fs = require "fs"
path = require "path"
{exec, spawn} = require "child_process"
async = require "async"
fileUtil = require "file"
_ = require "underscore"
sys = require "sys"


# copy single file and executes callback when done
exports.copyFile = (source, destination, callback) ->
  read = fs.createReadStream source
  write = fs.createWriteStream destination
  sys.pump read, write, -> callback()


# walk through tree, creates directories and copy files
exports.walkTreeAndCopyFiles = walkTree = (source, destination, callback) ->
  fs.readdir source, (error, files) ->
    return callback error if error

    # iterates over current directory
    async.forEach files, (file, next) ->
      return next() if file.match /^\./

      sourcePath = path.join source, file
      destinationPath = path.join destination, file

      fs.stat sourcePath, (error, stats) ->
        if not error and stats.isDirectory()
          fs.mkdir destinationPath, 0755, ->
            walkTree sourcePath, destinationPath, (error, destinationPath) ->
              if destinationPath
                callback error, destinationPath
              else
                next()
        else
          exports.copyFile sourcePath, destinationPath, ->
            callback error, destinationPath
            next()
    , callback


# recursive copy file tree from source to destination and fires
# callback with error and a list of created files
exports.recursiveCopy = (source, destination, callback) ->
  fileUtil.mkdirsSync destination, 0755
  paths = []
  # callback will be called several times
  walkTree source, destination, (err, filename) ->
    if err
      callback err
    else if filename
      paths.push filename
    else
      callback err, paths.sort()


# copied source from watch_dir, because it did not work as package
exports.watchDirectory = (_opts, callback) ->
  opts = _.extend(
    {path: ".", persistent: yes, interval: 500, callOnAdd: no},
    _opts
  )
  watched = []
  addToWatch = (file) ->
    fs.realpath file, (err, filePath) ->
      callOnAdd = opts.callOnAdd
      if _.include watched, filePath
        callOnAdd = yes
      else
        isDir = no
        watched.push filePath
        data = {persistent, interval} = opts
        fs.watchFile filePath, data, (curr, prev) ->
          return if curr.mtime.getTime() is prev.mtime.getTime()
          if isDir
            addToWatch filePath
          else
            callback filePath

      fs.stat filePath, (error, stats) ->
        if stats.isDirectory()
          isDir = yes
          fs.readdir filePath, (error, files) ->
            process.nextTick () ->
              addToWatch "#{filePath}/#{file}" for file in files
        else
          callback filePath if callOnAdd
  addToWatch opts.path

# Filter out dotfiles, emacs swap files and directories.
exports.filterFiles = (files, sourcePath) ->
  files.filter (filename) ->
    return no if filename.match /^(\.|#)/
    stats = fs.statSync path.join sourcePath, filename
    return no if stats?.isDirectory()
    yes

# return a string of available options
# originally taken from nomnom helpString
exports.optionsInfo = (options) ->
  output = "\n\nAvailable options:\n"
  for name, option of options
    output += "-#{option.abbr}\t--#{name}\t#{option.help}\n"
  output


# Shell color manipulation tools.
colors =
  foreground:
    black: 30
    red: 31
    green: 32
    brown: 33
    blue: 34
    purple: 35
    cyan: 36
    lgray: 37
    none: ''
    reset: 0

getColor = (color) ->
  color = color.toString()
  code = colors.foreground[color]
  code or colors.foreground.none


colorize = (text, color) ->
  "\033[#{getColor(color)}m#{text}
  \033[#{getColor('reset')}m"


pad = (number) ->
  num = "#{number}"
  if num.length < 2 then "0#{num}" else num


formatDate = (date = new Date) ->
  time = for item in ["Hours", "Minutes", "Seconds"]
    pad date["get#{item}"]()
  time.join ":"


format = (text, color) ->
  date = formatDate new Date
  "#{date}: #{colorize(text, color)}\n"


exports.isTesting = ->
  "describe" in global and "it" in global


hasGrowl = no
exec "which growlnotify", (error) -> hasGrowl = yes unless error?


exports.growl = (title, text) ->
  spawn "growlnotify", [title, "-m", text] if hasGrowl


exports.log = (text, color, isError = no) ->
  stream = if isError then process.stderr else process.stdout
  # TODO: log stdout on testing output end.
  stream.write (format text, color), "utf8" unless exports.isTesting()
  exports.growl "Brunch error", text if isError
 

exports.logSuccess = (text) -> exports.log text, "green"


exports.logError = (text) -> exports.log text, "red", yes


exports.exit = ->
  if exports.isTesting()
    exports.logError "Terminated process"
  else
    process.exit 0
