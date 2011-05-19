(function() {
  var Compiler, colors, fs, helpers, path;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  fs = require('fs');
  path = require('path');
  helpers = require('../helpers');
  colors = require('../../vendor/termcolors').colors;
  Compiler = require('./base').Compiler;
  exports.LessCompiler = (function() {
    __extends(LessCompiler, Compiler);
    function LessCompiler() {
      LessCompiler.__super__.constructor.apply(this, arguments);
    }
    LessCompiler.prototype.filePattern = function() {
      return [/\.less$/];
    };
    LessCompiler.prototype.compile = function(files) {
      var less, main_file_path;
      less = require('less');
      main_file_path = path.join(this.options.brunchPath, 'src/app/styles/main.less');
      return fs.readFile(main_file_path, 'utf8', __bind(function(err, data) {
        var parser;
        if (err != null) {
          return helpers.log(colors.lred('less err:   ' + err));
        } else {
          parser = new less.Parser({
            paths: [path.join(this.options.brunchPath, 'src')],
            filename: main_file_path
          });
          return parser.parse(data, function(err, tree) {
            var css;
            if (err != null) {
              return helpers.log(colors.lred('less err:   ' + err));
            } else {
              css = tree.toCSS({
                compress: true
              });
              return fs.writeFile(path.join(this.options.buildPath, 'web/css/main.css'), css, 'utf8', __bind(function(err) {
                if (err != null) {
                  return helpers.log(colors.lred('less err:   ' + err));
                } else {
                  return helpers.log("less:     " + (colors.green('compiled', true)) + " main.css\n");
                }
              }, this));
            }
          });
        }
      }, this));
    };
    return LessCompiler;
  })();
}).call(this);
