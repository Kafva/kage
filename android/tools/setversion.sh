#!/usr/bin/env bash
# To exclude changes from git (and get a non -dirty build)
#   git update-index --assume-unchanged src/main/res/values/version.xml
XML="$1"

VERSION=$(git describe --tags)
[ -n "$(git status -s)" ] && DIRTY="-dirty"

cat << EOF > $XML
<resources>
    <string name="git_version" translatable="false">${VERSION}${DIRTY}</string>
</resources>
EOF
