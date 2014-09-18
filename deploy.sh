#!/bin/bash
set -e

# Travis can only deploy from this branch
DEPLOY_BRANCH=deploy
# Deploy built site to this branch
TARGET_BRANCH=lets-try-react
# Sync the contents of this directory where the site should have been built
SITE_DIR=_site

if [ ! -d "$SITE_DIR" ]; then
  echo "SITE_DIR ($SITE_DIR) does not exist, build the site directory before deploying"
  exit 1
fi

REPO=$(git config remote.origin.url)

if [ -n "$TRAVIS_BUILD_ID" ]; then
  # When running on Travis we need to use SSH to deploy to GitHub
  #
  # The following converts the repo URL to an SSH location,
  # decrypts the SSH key and sets up the Git config with
  # the correct user name and email
  #
  # Set the following environment variables in the travis configuration (.travis.yml)
  #
  #   ENCRYPTION_LABEL - The label assigned when encrypting the SSH key using travis encrypt-file
  #   GIT_NAME         - The Git user name
  #   GIT_EMAIL        - The Git user email
  #   DEPLOY_BRANCH    - The only branch that Travis should deploy from
  #
  echo ENCRYPTION_LABEL: $ENCRYPTION_LABEL
  echo GIT_NAME: $GIT_NAME
  echo GIT_EMAIL: $GIT_EMAIL
  echo DEPLOY_BRANCH: $DEPLOY_BRANCH
  if [ "$TRAVIS_BRANCH" != "$DEPLOY_BRANCH" ]; then
    echo "Travis should only deploy from the DEPLOY_BRANCH ($DEPLOY_BRANCH) branch"
    exit 1
  else
    if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
      echo "Travis should not deploy from pull requests"
      exit 1
    else
      ENCRYPTED_KEY_VAR=encrypted_${ENCRYPTION_LABEL}_key
      ENCRYPTED_IV_VAR=encrypted_${ENCRYPTION_LABEL}_iv
      ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
      ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
      REPO=${REPO/git:\/\/github.com\//git@github.com:}
      openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in id_rsa.enc -out id_rsa -d
      chmod 600 id_rsa
      eval `ssh-agent -s`
      ssh-add id_rsa
      git config user.name "$GIT_NAME"
      git config user.email "$GIT_EMAIL"
    fi
  fi
fi

REPO_NAME=$(basename $REPO)
DIR=$(mktemp -d /tmp/$REPO_NAME.XXXX)
REV=$(git rev-parse HEAD)
git clone --branch ${TARGET_BRANCH} ${REPO} ${DIR}
rsync -rt --delete --exclude=".git" --exclude=".nojekyll" --exclude=".travis.yml" $SITE_DIR/ $DIR/
cd $DIR
git add -A .
git commit -m "Built from commit $REV"
git push $REPO $TARGET_BRANCH
