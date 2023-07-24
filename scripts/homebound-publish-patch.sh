#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PATCH_PACKAGE_NAME="@homebound/date-fns-patch"

WORKING_DIR="$SCRIPT_DIR"/../tmp
BUILD_DIR="$WORKING_DIR/date-fns"
PATCH_DIR="$WORKING_DIR/patch"

BRANCH_TO_MERGE="$1"
if [[ -z "$BRANCH_TO_MERGE" ]]; then
  echo "You must pass the name of the branch with homebound-specific changes as a param! (e.g., ./scripts/homebound/publish-patch.sh BRANCH_NAME)"
  exit 1
fi

LATEST_UPSTREAM_VERSION=$(npm view date-fns version)
echo "The latest version of date-fns published to NPM is $LATEST_UPSTREAM_VERSION"

# Given the current upstream version we're merging with, we look for the next appropriate version for our
# @homebound/date-fns-patch package. This allows us to release multiple versions of our patch against the same upstream
# version (e.g., 2.28.0-rc.1, 2.28.0-rc.2, etc.)
get_patch_package_version() {
  local all_versions
  all_versions=$(npm view $PATCH_PACKAGE_NAME versions --json)

  i=1
  while true; do
    local possible_version="$LATEST_UPSTREAM_VERSION-rc.$i"
    local exists
    exists=$(echo "$all_versions" | jq 'index('\""$possible_version"\"')')

    if [[ "$exists" == "null" ]]; then
      echo "$possible_version"
      break
    else
      i=$((i + 1))
    fi
  done
}
NEW_PATCH_PACKAGE_VERSION=$(get_patch_package_version)
echo "We'll publish $PATCH_PACKAGE_NAME@$NEW_PATCH_PACKAGE_VERSION."

# This function keeps our fork's `master` branch up-to-date with the upstream project. Our fork's `master` branch should
# exactly represent `upstream`
merge_upstream_master() {
  git remote add upstream https://github.com/date-fns/date-fns.git
  git fetch upstream --tags
  git checkout master
  git pull upstream master --rebase
  git push origin master --follow-tags
}

build() {
  yarn install

  # Build types
  ./scripts/build/build.sh
  git add -A
  git commit -m "generate and commit types"

  # Then build the NPM package
  env VERSION=v"$LATEST_UPSTREAM_VERSION" ./scripts/release/writeVersion.js
  env VERSION=v"$LATEST_UPSTREAM_VERSION" PACKAGE_OUTPUT_PATH="$BUILD_DIR" ./scripts/build/package.sh
}

create_patch() {
  mkdir -p "$PATCH_DIR"
  cd "$PATCH_DIR"

  # Here, we scaffold out the @homebound/date-fns-patch NPM package
  cat >"$PATCH_DIR"/package.json <<EOL
{
  "name": "${PATCH_PACKAGE_NAME}",
  "version": "${NEW_PATCH_PACKAGE_VERSION}",
  "repository": "https://github.com/homebound-team/date-fns",
  "homepage": "https://github.com/homebound-team/date-fns/blob/homebound-patch-publish/README.md#using-homebounddate-fns-patch",
  "description": "Provides a patch file for date-fns. Intended for use with patch-package NPM package.",
  "scripts": {
    "postinstall": "bash ./scripts/copy-patch-to-installer.sh"
  },
  "peerDependencies": {
    "patch-package": "^6"
  },
  "devDependencies": {
    "patch-package": "^6",
    "date-fns": "${LATEST_UPSTREAM_VERSION}"
  }
}
EOL

  # This script is what's responsible for copying the patch file into the consuming project. It's run in the
  # `postinstall` NPM lifecycle script.
  mkdir "$PATCH_DIR"/scripts
  cat >"$PATCH_DIR"/scripts/copy-patch-to-installer.sh <<EOL
#! /bin/bash

SCRIPT_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
PATCH_FILE="\$SCRIPT_DIR/../patches/date-fns+${LATEST_UPSTREAM_VERSION}.patch"

mkdir -p ../../../patches && cp "\$PATCH_FILE" ../../../patches/
EOL

  npm i --ignore-scripts

  # Now, we replace the upstream date-fns package with our transpiled branch code. This allows `patch-package` to
  # produce the .patch file
  rm -fr "$PATCH_DIR/node_modules/date-fns"
  mv -f "$BUILD_DIR" "$PATCH_DIR/node_modules/"
  npx patch-package date-fns

  npm publish
}

echo "Merging upstream date-fns master branch to our fork..."
merge_upstream_master

echo "Checking out version $LATEST_UPSTREAM_VERSION by tag..."
git checkout "v$LATEST_UPSTREAM_VERSION"
git checkout -b "homebound-patch-v$NEW_PATCH_PACKAGE_VERSION"

echo "Merging $BRANCH_TO_MERGE..."
git merge --no-commit origin/"$BRANCH_TO_MERGE"
git push origin "homebound-patch-v$NEW_PATCH_PACKAGE_VERSION"

echo "Building..."
build
git push origin "homebound-patch-v$NEW_PATCH_PACKAGE_VERSION"

echo "Creating patch..."
create_patch "$LATEST_UPSTREAM_VERSION"
