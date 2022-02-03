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

merge_upstream_master() {
  git remote add upstream https://github.com/date-fns/date-fns.git
  git fetch upstream --tags
  git checkout master
  git pull upstream master --rebase
  git push origin master --follow-tags
}

create_patch() {
  mkdir -p "$PATCH_DIR"
  cd "$PATCH_DIR"

  cat >"$PATCH_DIR"/package.json <<EOL
{
  "name": "${PATCH_PACKAGE_NAME}",
  "version": "${NEW_PATCH_PACKAGE_VERSION}",
  "repository": "https://github.com/homebound-team/date-fns",
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

  mkdir "$PATCH_DIR"/scripts
  cat >"$PATCH_DIR"/scripts/copy-patch-to-installer.sh <<EOL
#! /bin/bash

SCRIPT_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
PATCH_FILE="\$SCRIPT_DIR/../patches/date-fns+${LATEST_UPSTREAM_VERSION}.patch"

mkdir -p ../../../patches && cp "\$PATCH_FILE" ../../../patches/
EOL

  npm i --ignore-scripts

  rm -fr "$PATCH_DIR/node_modules/date-fns"
  mv -f "$BUILD_DIR" "$PATCH_DIR/node_modules/"
  npx patch-package date-fns

  # TODO: remove dry run flag
  npm publish --dry-run
}

echo "Merging upstream date-fns master branch to our fork..."
merge_upstream_master

echo "Checking out version $LATEST_UPSTREAM_VERSION by tag..."
git checkout "v$LATEST_UPSTREAM_VERSION"
git checkout -b "homebound-patch-v$LATEST_UPSTREAM_VERSION"

echo "Merging $BRANCH_TO_MERGE..."
git merge --no-commit origin/"$BRANCH_TO_MERGE"

echo "Building..."
yarn install
env VERSION=v"$LATEST_UPSTREAM_VERSION" ./scripts/release/writeVersion.js
env VERSION=v"$LATEST_UPSTREAM_VERSION" PACKAGE_OUTPUT_PATH="$BUILD_DIR" ./scripts/build/package.sh

echo "Creating patch..."
create_patch "$LATEST_UPSTREAM_VERSION"
