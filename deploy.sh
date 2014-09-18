#!/bin/bash
set -e

# Travis can only deploy from this branch
DEPLOY_BRANCH=deploy
# Deploy built site to this branch
TARGET_BRANCH=lets-try-react
# Sync the contents of this directory where the site should have been built
SITE_DIR=_site
# Unique label associated with Travis file encryption variables
TRAVIS_FILE_ENCRYPTION_LABEL=e5350353280d

# Default these variables if not running in Travis so that
# deploys can be run locally from any branch 
PULL_REQUEST=${TRAVIS_PULL_REQUEST:-false}
BRANCH=${TRAVIS_BRANCH:-$DEPLOY_BRANCH}

if [ ! -d "$SITE_DIR" ]; then
  echo "SITE_DIR ($SITE_DIR) does not exist, build the site directory before deploying"
  exit 1
fi

if [ "$BRANCH" == "$DEPLOY_BRANCH" ]; then
  if [ "$PULL_REQUEST" == "false" ]; then
    REPO=$(git config remote.origin.url)
    ENCRYPTED_KEY_VAR=encrypted_${TRAVIS_FILE_ENCRYPTION_LABEL}_key
    ENCRYPTED_IV_VAR=encrypted_${TRAVIS_FILE_ENCRYPTION_LABEL}_iv
    ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
    ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
    if [ -n "$ENCRYPTED_KEY" ]; then
      # Use SSH and the supplied encrypted deploy key when deploying from Travis
      REPO=${REPO/git:\/\/github.com\//git@github.com:}
      openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in id_rsa.enc -out id_rsa -d
      chmod 600 id_rsa
      eval `ssh-agent -s`
      ssh-add id_rsa
    fi
    REPO_NAME=$(basename $REPO)
    DIR=$(mktemp -d /tmp/$REPO_NAME.XXXX)
    REV=$(git rev-parse HEAD)
    git clone --branch ${TARGET_BRANCH} ${REPO} ${DIR}
    rsync -rt --delete --exclude=".git" --exclude=".nojekyll" --exclude=".travis.yml" $SITE_DIR/ $DIR/
    cd $DIR
    if [ -n "$GIT_NAME" ]; then
      git config user.name "$GIT_NAME"
    fi
    if [ -n "$GIT_EMAIL" ]; then
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
fi
