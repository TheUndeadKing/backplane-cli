#!/bin/bash
# Manual release steps for reference:
# https://github.com/openshift/backplane-cli/blob/main/docs/release.md

set -e

# Ensure GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN is not set in ci-release.sh."
    exit 1
else
    echo "GITHUB_TOKEN is set in ci-release.sh"
fi

# Define repository URL with token
REPO_URL="https://${GITHUB_TOKEN}@github.com/openshift/backplane-cli.git"

# Extract version from VERSION.md
VERSION=$(grep 'Version:' VERSION.md | awk '{print $2}')

# Check if version is extracted correctly
if [ -z "$VERSION" ]; then
    echo "Error: Failed to extract version from VERSION.md"
    exit 1
fi

# Check if the tag already exists in the repository
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
    echo "Error: Tag v$VERSION already exists. Aborting release."
    exit 1
fi

# Git configurations
git config user.name "CI release"
git config user.email "ci-test@release.com"

# Ensure the remote repository 'upstream' is set to the correct URL
if git remote | grep -iq 'upstream'; then
    current_url=$(git remote get-url upstream)
    if [ "$current_url" != "$REPO_URL" ]; then
        git remote set-url upstream $REPO_URL
    fi
else
    git remote add upstream $REPO_URL
fi

# Ensure working on the latest main
git fetch upstream
git checkout upstream/main

# Tagging the release
git tag -a "v${VERSION}" -m "Release v${VERSION}"

# Print the remote URL again before pushing
echo "Final upstream URL before push:"
git remote -v

# Push the tag to the remote repository
git push upstream "v${VERSION}"
