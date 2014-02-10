---
layout: post
title:  "NodeJS - Getting test coverage from child processes"
date:   2014-02-09 16:23:38
categories: NodeJS test coverage Javascript
---

This is a problem that I keep running into. I like to use a combination of `Grunt`, `Mocha` and `Blanket` to get coverage reports from my unit tests. The problem is that this creates a global variable to collect the coverage data in the process in which the code under test runs. Normally this is the same process in which `Grunt` and `Mocha` are running, however I have a common class of tests in which this is not true.

When I want to perform an end to end integration test or test an entry point to a command line tool then usually I want to use `child_process.exec` or `child_process.spawn` to kick it off. This first became apparent when I wanted to test a plugin for `Grunt` itself, `grunt-mocha-test`. The workaround was to create a special script that could be launched in place of `Grunt` that would programatically call `Grunt`, collect the coverage data and then write it to a file. This script would then be launched by a wrapper to `child_process.exec` that would collect the coverage data after the exec had completed and merge it with the coverage data from the parent process.

This works well but is not very portable. The challenge then is to create a generic solution to the problem.
