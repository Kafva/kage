#!/usr/bin/env bash
set -e
#
# This script runs automatically with each build and updates the Info.plist with
# every new commit, exclude local changes to it with:
#
# git update-index --assume-unchanged src/Info.plist
#
plist_cmd() {
    /usr/libexec/PlistBuddy -c "$1" "${SOURCE_ROOT?}/src/Info.plist" 2> /dev/null || :
}

# Make sure the Xcode project version is up to date
XCODE_VERSION="v$(awk '/MARKETING_VERSION/ {print substr($3,0,length($3)-1); exit}' \
            ${PROJECT_FILE_PATH?}/project.pbxproj)"
GIT_VERSION="$(git tag -l|tail -n1)"

if [ "$XCODE_VERSION" != "$GIT_VERSION" ]; then
    echo "Update MARKETING_VERSION: $XCODE_VERSION (xcode) != $GIT_VERSION (git)"
    exit 1
fi

[ -n "$(git status -s)" ] && DIRTY="-dirty"

# Recreate the key with the current git version
plist_cmd "Add :GitVersion string"
plist_cmd "Set :GitVersion $(git describe --tags)$DIRTY"
