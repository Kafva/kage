#!/usr/bin/env bash
set -e

#
# Build script for iOS
#

CURDIR=$(cd "$(dirname $0)" && pwd)

# SOURCE_ROOT is set from Xcode to kage/ios, default to the same path
# when invoked manually.
SOURCE_ROOT=${SOURCE_ROOT:-"${CURDIR}/../ios"}
PLATFORM_DISPLAY_NAME=${PLATFORM_DISPLAY_NAME:-"iOS Simulator"}
CONFIGURATION=${CONFIGURATION:-Debug}

PATH="$PATH:$HOME/.cargo/bin"
LIB="libkage_core.a"
DIST=$SOURCE_ROOT/dist
CARGO_BUILDTYPE=release

rm -f "$DIST/*.{a,so,rlib}"

case "$PLATFORM_DISPLAY_NAME" in
"iOS Simulator")
    if [ "$(uname -m)" = x86_64 ]; then
        CARGO_TARGET=x86_64-apple-ios
    else
        CARGO_TARGET=aarch64-apple-ios-sim
    fi
;;
"iOS")
    CARGO_TARGET=aarch64-apple-ios
;;
*)
    echo "Unsupported platform"
    exit 1
;;
esac

cargo \
    -Z unstable-options \
    -C $SOURCE_ROOT/../core \
    rustc \
    --lib \
    --crate-type staticlib \
    --release \
    --target ${CARGO_TARGET}

# Always copy the output for the current platform to dist
mkdir -p "$DIST"
cp "$SOURCE_ROOT/../core/target/${CARGO_TARGET}/${CARGO_BUILDTYPE}/$LIB" \
   "$DIST/$LIB"
