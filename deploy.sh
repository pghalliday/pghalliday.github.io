#!/bin/bash
set -e

# Travis can only deploy from this branch
DEPLOY_BRANCH=deploy

# Deploy built site to this branch
TARGET_BRANCH=lets-try-react

# Sync the contents of this directory where the site should have been built
SITE_DIR=_site

# Travis variables for decrypting the GitHub deploy key. If these
# are not set then local ssh keys should be set
ENCRYPTED_KEY=$encrypted_e5350353280d_key
ENCRYPTED_IV=$encrypted_e5350353280d_iv

# Default these variables if not running in Travis so that
# deploys can be run locally from any branch 
PULL_REQUEST=${TRAVIS_PULL_REQUEST:-false}
BRANCH=${TRAVIS_BRANCH:-deploy}

if [ ! -d "$SITE_DIR" ]; then
  echo "SITE_DIR ($SITE_DIR) does not exist, build the site directory before deploying"
  exit 1
fi

if [ "$BRANCH" == "$DEPLOY_BRANCH" ]; then
  if [ "$PULL_REQUEST" == "false" ]; then
    REPO=$(git config remote.origin.url)
    if [ -n "$ENCRYPTED_KEY" ]; then
      # Use SSH and the supplied encrypted deploy key when deploying from Travis
      REPO=${REPO/git:\/\/github.com\//git@github.com:}
      openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in id_rsa.enc -out id_rsa -d
      chmod 600 id_rsa
      ssh-add id_rsa
    fi
    DIR=$(mktemp -d /tmp/pghalliday.github.io.XXXX)
    REV=$(git rev-parse HEAD)
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