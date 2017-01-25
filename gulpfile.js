var gulp = require('gulp');
var livereload = require('gulp-livereload');
var watch = require('gulp-watch');
var plumber = require('gulp-plumber');
var spawn = require('child_process').spawn;
var express = require('express');
var path = require('path');
var del = require('del');

var port = process.env.PORT || 4000;

function exec_async(cmd, args, cb) {
  var child = spawn(cmd, args, {
    stdio: 'inherit'
  });
  child.on('exit', function(code, signal) {
    var error = null;
    if (code || signal) {
      error = new Error(cmd + ' exited with code: ' + code + ' and signal: ' + signal);
    }
    cb(error);
  });
}

gulp.task('clean', function(next) {
  del(['vendor'], next);
});

gulp.task('bootstrap', ['clean'], function() {
  return gulp.src('bower_components/bootstrap/dist/**/*.{min.css,min.js,eot,svg,ttf,woff}')
  .pipe(gulp.dest('vendor/bootstrap'));
});

gulp.task('jquery', ['clean'], function() {
  return gulp.src('bower_components/jquery/dist/**/*.min.js')
  .pipe(gulp.dest('vendor/jquery'));
});

gulp.task('jekyll', ['bootstrap', 'jquery'], function(next) {
  exec_async('jekyll', ['build'], next);
});

gulp.task('jekyll-drafts', ['bootstrap', 'jquery'], function(next) {
  exec_async('jekyll', ['build', '--drafts'], next);
});

gulp.task('server', function(next) {
  var server = express();
  server
  .use(express.static(path.resolve('_site')))
  .listen(port, next);
});

gulp.task('watch', ['jekyll-drafts', 'server'], function() {
  watch([
    '_drafts/**/*',
    '_layouts/**/*',
    '_posts/**/*',
    'bower_components/**/*',
    'css/**/*',
    '*.html',
    'CNAME'
  ], function() {
      gulp.start('jekyll-drafts');
  });
  livereload.listen();
  watch('_site/**/*', function(files) {
    return files.pipe(plumber()).pipe(livereload());
  });
});
