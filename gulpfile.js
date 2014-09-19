var gulp = require('gulp');
var livereload = require('gulp-livereload');
var watch = require('gulp-watch');
var spawn = require('child_process').spawn;
var express = require('express');
var path = require('path');

var port = process.env.PORT || 4001;

gulp.task('default', function() {
  // place code for your default task here
});

gulp.task('jekyll', ['default'], function() {
  spawn('jekyll', [
    'build'
  ], {
    stdio: 'inherit'
  });
});

gulp.task('server', function(next) {
  var server = express();
  server.use(express.static(path.resolve('_site'))).listen(port, next);
});

gulp.task('watch', ['jekyll', 'server'], function() {
  watch([
    '_drafts/**/*',
    '_layouts/**/*',
    '_posts/**/*',
    'bower_components/**/*',
    'css/**/*',
    'index.html'
  ], function() {
      gulp.start('jekyll');
  });

  watch('_site/**/*', function(files) {
      return files.pipe(livereload());
  });
});

gulp.task('build', ['jekyll']);
