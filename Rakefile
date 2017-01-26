require_relative 'lib/bower_component_tasks'

namespace :build do
  include BowerComponentTasks

  task :clean do
    rm_rf 'vendor'
  end

  multitask :bower_components => bower_component_tasks(
    'bootstrap' => '**/*.{min.css,min.js,eot,svg,ttf,woff}',
    'jquery' => '**/*.min.js'
  )

  task :vendor => [:clean, :bower_components]
end

task :default => 'build:vendor'
