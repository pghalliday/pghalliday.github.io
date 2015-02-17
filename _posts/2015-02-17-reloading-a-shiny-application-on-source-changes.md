---
layout: post
title:  "Reloading a Shiny application on source changes"
categories: watch shell shiny inotify-tools guard guard-livereload guard-process livereload
disqus_identifier: reloading-a-shiny-application-on-source-changes
---

I have been trying to implement watching for changes to source code and auto reloading a [Shiny](http://shiny.rstudio.com/) application. The problem being that Shiny applications only reload changes to `server.R` and `ui.R` by default, which isn't so useful when your app gets complicated and you want to make it more modular.

Option 1 - Shell goodness :)
----------------------------

Initially I wanted to add minimal new stuff to my tool chain so I was looking for something that I could do in a shell script. My initial solution was `inotify-tools`. Simple to install:

```sh
sudo apt-get install inotify-tools
```

And once I got my head around some shell scripts malarkey, simple to configure by creating a `watch.sh` script:

```sh
#!/bin/sh

WATCHED_DIR=${1-./app}
PORT=${2-5001}

start () {
  R -e "shiny::runApp('$WATCHED_DIR', port = $PORT)" &
  PID=$!
}

start

inotifywait -mr $WATCHED_DIR --format '%e %f' \
  -e modify -e delete -e move -e create \
  | while read event file; do

  echo $event $file

  kill $PID
  start

done
```

By default this watches `./app` directory and restarts the Shiny application on port `5000` whenever a file or directory change is detected (modified, deleted, moved or created). You can also override the path and port on the command line, eg:

```sh
./watch.sh ./src 5001
```

Awesome :) and I'm so pleased with it that I just had to record it here for posterity. The fact is though that I don't use it anymore (I used it for about 5 minutes). The reason being that next I wanted to integrate [LiveReload](http://livereload.com) to also refresh my browser window on updates.

Option 2 - Ruby magic!
----------------------

The simplest way for me to run a LiveReload server was with the `guard-livereload` ruby gem. This means installing `guard` and running that. So let's face it, if I'm going to run guard anyway, there's not much point reloading the application with `inotifywait` when I could also use `guard-process`. So I made sure I had ruby and bundler installed:

```sh
sudo apt-get install ruby
sudo apt-get install ruby-dev
sudo gem install bundler
```

Created the following `Gemfile`:

```ruby
source "https://rubygems.org"

gem 'guard'
gem 'guard-livereload'
gem 'guard-process'
```

And installed dependencies:

```sh
bundle install
```

Created the following `Guardfile`:

```ruby
dir = 'app'
port = 5000

guard 'livereload' do
  watch(%r{#{dir}/.+\.R$})
end

guard 'process', name: 'Shiny', command: ['R', '-e', "shiny::runApp('#{dir}', port = #{port})"] do
  watch(%r{#{dir}/.+\.R$})
end
```

Now running:

```sh
bundle exec guard
```

- Launches my application on port 5000
- Watches for changes then
  - reloads the application
  - reloads connected browsers running the LiveReload plugin
