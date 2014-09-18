#!/bin/bash
set -e

DEPLOY_BRANCH=deploy
TARGET_BRANCH=lets-try-react
SITE_DIR=_site

PULL_REQUEST=${TRAVIS_PULL_REQUEST:-false}
BRANCH=${TRAVIS_BRANCH:-deploy}

if [ ! -d "$SITE_DIR" ]; then
  echo "SITE_DIR ($SITE_DIR) does not exist, build the site directory before deploying"
  exit 1
fi

if [ "$BRANCH" == "$DEPLOY_BRANCH" ]; then
  if [ "$PULL_REQUEST" == "false" ]; then
    if [ -n "$encrypted_e5350353280d_key" ]; then
      openssl aes-256-cbc -K $encrypted_e5350353280d_key -iv $encrypted_e5350353280d_iv -in id_rsa.enc -out id_rsa -d
      chmod 600 id_rsa
      ssh-add id_rsa
    fi
    DIR=$(mktemp -d /tmp/pghalliday.github.io.XXXX)
    REV=$(git rev-parse HEAD)
    REPO=$(git config remote.origin.url)
    git clone --branch ${TARGET_BRANCH} ${REPO} ${DIR}
    rsync -rt --delete --exclude=".git" --exclude=".nojekyll" --exclude=".travis.yml" $SITE_DIR/ $DIR/
    cd $DIR
    if [ -z "$GIT_NAME" ]; then
      git config user.name "$GIT_NAME"
    fi
    if [ -z "$GIT_EMAIL" ]; then
      git config user.email "$GIT_EMAIL"
    fi
    git add -A .
    git commit -m "Built from commit $REV"
    git push $REPO $TARGET_BRANCH
  else
    echo "Should not deploy from pull requests"
    exit 1
  fi
else
  echo "Can only deploy from the DEPLOY_BRANCH ($DEPLOY_BRANCH) branch"
  exit 1
if