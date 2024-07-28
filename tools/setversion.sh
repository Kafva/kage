#!/usr/bin/env bash
set -ex
#
# This script runs automatically with each build and updates the Info.plist with
# every new commit, exclude local changes to it with:
#
# git update-index --assume-unchanged ios/Info.plist
#
INFO_PLIST="${SOURCE_ROOT?}/ios/Info.plist"
KEY="GitVersion"
DIRTY=

# Make sure the Xcode project version is up to date
XCODE_VERSION="v$(awk '/MARKETING_VERSION/ {print substr($3,0,length($3)-1); exit}' \
            ${PROJECT_FILE_PATH?}/project.pbxproj)"
GIT_VERSION="$(git tag -l|tail -n1)"

if [ "$XCODE_VERSION" != "$GIT_VERSION" ]; then
    echo "Update MARKETING_VERSION: $XCODE_VERSION (xcode) != $GIT_VERSION (git)"
    exit 1
fi


[ -n "$(git status -s)" ] && DIRTY="-dirty"

# Add key if missing
/usr/libexec/PlistBuddy -c \
    "Add :$KEY string" \
    "${INFO_PLIST}" 2> /dev/null || :

# Update with current tag and commit
/usr/libexec/PlistBuddy -c \
    "Set :$KEY $(git describe --tags)$DIRTY" \
    "${INFO_PLIST}"
