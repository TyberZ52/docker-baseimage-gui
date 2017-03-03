#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

TARGET_BRANCH=deploy-$TAG
REPO=$(git config remote.origin.url)

# Adjust git configuration.
git config remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# Update repository to get all remote branches.
echo "Updating repository..."
git fetch

# Switch to proper branch and sync it with master.
echo "Checking out branch $TARGET_BRANCH..."
if git branch -a | grep -w -q $TARGET_BRANCH; then
    git checkout --track origin/$TARGET_BRANCH
else
    git branch $TARGET_BRANCH
    git checkout $TARGET_BRANCH
fi

# Merge the master branch.
echo "Merging master in $TARGET_BRANCH..."
git merge --no-edit master

# Generate and validate the Dockerfile.
echo "Generating and validating the Dockerfile..."
travis/before_script.sh
sed -i "1s/^/# DO NOT EDIT - Dockerfile generated by Travis CI (Build $TRAVIS_BUILD_NUMBER)\n/" Dockerfile

# Add and commit the Dockerfile.
git add Dockerfile
git commit \
    --allow-empty \
    -m "Automatic Dockerfile deployment from Travis CI (build $TRAVIS_BUILD_NUMBER)." \
    --author="Travis CI <$COMMIT_AUTHOR_EMAIL>"

# Push changes.
echo "The following commit will be pushed to branch $TARGET_BRANCH:"
git show
echo "Pushing changes to repository..."
git push ${REPO/https:\/\//https:\/\/$GIT_PERSONAL_ACCESS_TOKEN@} $TARGET_BRANCH
