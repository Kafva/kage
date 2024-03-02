#!/usr/bin/env bash
set -e

CURDIR=$(cd "$(dirname $0)" && pwd)

# Defaults for environment variables passed by Xcode
SOURCE_ROOT=${SOURCE_ROOT:-"${CURDIR}/.."}
PLATFORM_DISPLAY_NAME=${PLATFORM_DISPLAY_NAME:-"iOS Simulator"}
CONFIGURATION=${CONFIGURATION:-Debug}
PATH="$PATH:$HOME/.cargo/bin"
LIB="libkage_core.a"

OUT="${SOURCE_ROOT:-}/out"
CARGO_FLAGS=

mkdir -p "$OUT"

case "$PLATFORM_DISPLAY_NAME" in
"iOS Simulator")
    if [ "$CONFIGURATION" != Debug ]; then
        echo "Simulator should use debug configuration"
        exit 1
    fi

    CARGO_BUILDTYPE=debug
    CARGO_FLAGS+=" --features simulator"

    if [ "$(uname -m)" = x86_64 ]; then
        CARGO_TARGET=x86_64-apple-ios
    else
        CARGO_TARGET=aarch64-apple-ios-sim
    fi
;;
"iOS")
    CARGO_BUILDTYPE=release
    CARGO_FLAGS+=" --release"

    CARGO_TARGET=aarch64-apple-ios
;;
*)
    echo "Unsupported platform"
    exit 1
;;
esac


(cd $SOURCE_ROOT/kage-core &&
    cargo build ${CARGO_FLAGS} --target ${CARGO_TARGET})

cp "$SOURCE_ROOT/kage-core/target/${CARGO_TARGET}/${CARGO_BUILDTYPE}/$LIB" \
   "$OUT/$LIB"
