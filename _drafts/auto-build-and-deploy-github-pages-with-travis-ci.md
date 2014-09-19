---
layout: post
title:  "Auto build and deploy GitHub pages with Travis-CI"
categories: GitHub SSH Travis-CI
disqus_identifier: auto-build-and-deploy-github-pages-with-travis-ci
---

So you have an existing Jekyll GitHub pages project but you also have some preliminary build steps and/or tests that you need to run before pushing to GitHub to deploy. Now you're tired of running these steps manually and keeping the built artifacts in your repository. One answer (and the answer illustrated here) is to use Travis-CI to automate the build and deploy steps for you and retire the automatic Jekyll build that GitHub would perform. So here goes...  

First checkout the GitHub pages project to a new `deploy` branch.

```
git checkout -b deploy
git push -u origin deploy
```

Enable Travis-CI on your GitHub pages project.

Set `deploy` to be the default branch in the GitHub web interface. This will be the branch that you do most of your work in or make future branches from, so it makes sense for it to be the default. You will no longer manually make changes to the `master` branch.

Add the SSH key entries to `.gitignore` as illustrated here

<script src="https://gist.github.com/pghalliday/240fe740d523dad21d3f.js?file=gitignore.sh"></script>

Generate a private/public key pair without passphrase in the repo directory

```
ssh-keygen -t rsa -C "your_email@example.com" -f id_rsa -N ''
```

Add the public key (`id_rsa.pub`) to the GitHub repository as a 'Deploy Key' through the web interface. We are using deploy keys so that we can make them specific to a single repository. An alternative approach could use 'Personal access tokens' but they would then allow access to all repositories associated with the given account - this might be preferable if special GitHub accounts are created specifically for Travis builds and they need to work with multiple repositories.

Install the travis gem

```
gem install travis
```

Login to travis with your GitHub credentials

```
travis login
```

Encrypt the SSH key to generate `id_rsa.enc`

```
travis encrypt-file id_rsa
```

Add the `deploy.sh` file as given here and mark it executable

<script src="https://gist.github.com/pghalliday/240fe740d523dad21d3f.js?file=auto-build-and-deploy-github-pages-with-travis-ci.sh"></script>

```
chmod +x deploy.sh
```

Add a `.travis.yml` to the branch as given here

<script src="https://gist.github.com/pghalliday/240fe740d523dad21d3f.js?file=deploy.travis.yml"></script>

Add a `build` task to your `Rakefile` that at least calls `jekyll build` but should also perform the additional build and test steps that you wanted Travis-CI to do in the first place.

Commit your changes to the `deploy` branch but don't push them yet

```
git add -A .
git commit -m "adding travis auto build and deploy support"
```

Switch back to the `master` branch that GitHub will use for the source of your GitHub pages site

```
git checkout master
```

Delete all the existing files and create a `.nojekyll` file to let GitHub know that it does not need to run Jekyll again.

Add a `.travis.yml` file to the `master` branch as given here to prevent Travis-CI building the master branch when it changes. After all there is nothing for Travis-CI to do in the master branch

<script src="https://gist.github.com/pghalliday/240fe740d523dad21d3f.js?file=master.travis.yml"></script>

Commit the `master` branch and push both branches back to GitHub

```
git add -A .
git commit -m "Prepare master branch as a deployment target"
git push --all
```

This will trigger Travis-CI to do its first deployment from the `deploy` branch.

