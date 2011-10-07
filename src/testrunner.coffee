sys = require "sys"
fs = require "fs"
path = require "path"
coffee = require "coffee-script"
jsdom = require "jsdom"


{TerminalReporter} = require __dirname + "/../vendor/reporter"


# TODO: find a better way to do this.
# https://github.com/brunch/brunch/pull/111#issuecomment-2244266
TEMP = "/tmp/brunchtest"


exports.run = (options) ->
  brunchdir = path.resolve options.brunchPath
  testdir = path.join brunchdir, "test"
  console.log "Running tests in " + testdir

  # Compiles specs in `dir` and appends the result to `list`
  getSpecFiles = (dir, list) ->
    for f in fs.readdirSync(dir)
      filepath = path.join(dir, f)
      ext = path.extname(filepath)
      if ext in [".coffee", ".js"]
        spec = fs.readFileSync filepath, "utf-8"
        spec = coffee.compile(spec) if ext is ".coffee"
        list.push spec
      else if fs.statSync(filepath).isDirectory()
        getSpecFiles filepath, list

  specs = []
  getSpecFiles testdir, specs

  # Remove temporary folder if it already exists
  try
    if fs.statSync("/tmp/brunchtest").isDirectory()
      for f in fs.readdirSync TEMP
        fs.unlinkSync path.join TEMP, f
      fs.rmdirSync TEMP

  fs.mkdir TEMP, 0755, ->
    # Write specs to temporary folder
    fs.writeFileSync TEMP + "/specs.js", specs.join "\n"

    # Run specs in fake browser
    jsdom.env
      html: path.join brunchdir, "index.html"
      scripts: [
        path.join brunchdir, "build/web/js/app.js"
        path.resolve __dirname, "../vendor/jasmine.js"
        "/tmp/brunchtest/specs.js"
      ]
      done: (errors, window) ->
        jasmineEnv = window.jasmine.getEnv()
        jasmineEnv.reporter = new TerminalReporter
          print: sys.print
          verbose: no
          color: yes
          onComplete: null
          stackFilter: null
        jasmineEnv.execute()

