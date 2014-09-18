---
layout: post
title:  "Auto build and deploy GitHub pages with Travis-CI"
categories: GitHub SSH Travis-CI
disqus_identifier: auto-build-and-deploy-github-pages-with-travis-ci
---

set up branches
---------------

- `master` - actual site is served from this source
  - `.nojenkins`
    - Tell GitHub we already built everything and not to run Jekyll
  - `.travis.yml`
    - Tell Travis-CI to ignore the master branch as it's where we deploy to

    ```
    branches:
      except:
        - master
    ```

- `deploy` - the source and build scripts live here, using gulp to test and transform source, then jekyll to build the site the output goes into `_site`
  - `.travis.yml`
    - configure test, build and add `after_success` script

    ```
    after_success:
    - ./deploy.sh
    ```

  - `deploy.sh`
    - This script can be used locally or in Travis to push the contents of `_site` to the `master` branch
