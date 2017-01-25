---
layout: post
title:  "Submitting Mocha BDD test results to Sonar"
categories: NodeJS test coverage Sonar Mocha BDD Javascript
disqus_identifier: submitting-mocha-bdd-test-results-to-sonar
comments: true
---

I like to use [Mocha](http://visionmedia.github.io/mocha/) with the BDD test UI to write my tests and in the office at least, use [Sonar](http://www.sonarqube.org/) to collect test and coverage data as well as perform static analysis on source code. For Javascript projects this means using the [Sonar javascript plugin](http://docs.codehaus.org/display/SONAR/JavaScript+Plugin).

A typical `sonar-project.properties` configuration file will look like this.

```
sonar.projectKey=app:my-app
sonar.projectName=My Application
sonar.projectVersion=1.0

sonar.sources=lib/src
sonar.language=js

sonar.javascript.jstestdriver.reportsPath=reports
sonar.javascript.lcov.reportPath=reports/lcov.info
```

This tells Sonar that my test results will be in the `reports` directory and that coverage data will be located at `reports/lcov.info`

The Sonar javascript plugin supports coverage data in the `lcov` format and test reports in the `xunit` format.

For my NodeJS projects I use my [`grunt-mocha-test`](https://github.com/pghalliday/grunt-mocha-test) plugin to generate the reports. In this case we can use the [`mocha-lcov-reporter`](https://github.com/StevenLooman/mocha-lcov-reporter) to generate the coverage report. However when using the standard `xunit` reporter to generate the test report 2 problems become apparent when the reports are submitted to Sonar.

- Sonar will reject reports that have a `classname` that mirrors a source file, eg. if you have a source file called `MyClass.js` then you cannot have a test with a `classname` of `MyClass` (the standard `xunit` reporter uses the contents of the `Describe` text as the classname, so for me this happens a lot!)
- Sonar interprets the `classname` field as a filename resulting in hard to read test reports in the Sonar UI (this is probably also the cause of the first issue)

The solution for me was to create a new reporter for Mocha based on the `xunit` reporter.

[`mocha-sonar-reporter`](https://github.com/pghalliday/mocha-sonar-reporter) will generate `xunit` output that uses the concatenation of the suite and test titles as the test `name` and set the `classname` to a configurable constant so that name collisions can be avoided. If no `classname` is configured it will default to `Test`.
