#!/usr/bin/env bash
set -e

#
# Build script for iOS and Android
#

CURDIR=$(cd "$(dirname $0)" && pwd)

PATH="$PATH:$HOME/.cargo/bin"
CARGO_BUILDTYPE=release

case "$1" in
android)
    SOURCE_ROOT=${SOURCE_ROOT:-"${CURDIR}/../android"}

    LIB="libkage_core.so"
    CARGO_CRATE_TYPE=dylib
    # XXX: Hardcoded target ABI
    DIST=$SOURCE_ROOT/app/src/main/jniLibs/arm64-v8a
    CARGO_TARGET=aarch64-linux-android
;;
*)
    # SOURCE_ROOT is set from Xcode to kage/ios, default to the same path
    # when invoked manually.
    SOURCE_ROOT=${SOURCE_ROOT:-"${CURDIR}/../ios"}
    PLATFORM_DISPLAY_NAME=${PLATFORM_DISPLAY_NAME:-"iOS Simulator"}
    CONFIGURATION=${CONFIGURATION:-Debug}

    LIB="libkage_core.a"
    CARGO_CRATE_TYPE=staticlib
    DIST=$SOURCE_ROOT/dist

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
;;
esac

rm -f "$DIST/*.{a,so,rlib}"

# Always build with --release when bundling for ffi
cargo \
    -Z unstable-options \
    -C $SOURCE_ROOT/../core \
    rustc \
    --lib \
    --crate-type ${CARGO_CRATE_TYPE} \
    --release \
    --target ${CARGO_TARGET}

# Always copy the output for the current platform to dist
mkdir -p "$DIST"
cp -v "$SOURCE_ROOT/../core/target/${CARGO_TARGET}/${CARGO_BUILDTYPE}/$LIB" \
      "$DIST/$LIB"
