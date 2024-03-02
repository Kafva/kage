#!/usr/bin/env bash
set -e

CURDIR=$(cd "$(dirname $0)" && pwd)

# Defaults for environment variables passed by Xcode
# XXX: Default to simulator build
SOURCE_ROOT=${SOURCE_ROOT:-"${CURDIR}/.."}
CONFIGURATION=${CONFIGURATION:-Debug}
PLATFORM_DISPLAY_NAME=${PLATFORM_DISPLAY_NAME:-"iOS Simulator"}
PATH="$PATH:$HOME/.cargo/bin"

OUT="${SOURCE_ROOT:-}/out"
CARGO_FLAGS=

mkdir -p "$OUT"

if [ $CONFIGURATION = Release ]; then 
    CARGO_FLAGS+=" --release"
fi

case "$PLATFORM_DISPLAY_NAME" in
"iOS Simulator")
    if [ "$(uname -m)" = x86_64 ]; then
        CARGO_TARGET=x86_64-apple-ios
    else
        CARGO_TARGET=aarch64-apple-ios-sim
    fi
    CARGO_FLAGS+=" --features simulator"
;;
"iOS")
    CARGO_TARGET=aarch64-apple-ios
;;
*)
    echo "Unsupported platform"
    exit 1
;;
esac


(cd $SOURCE_ROOT/kage-core && 
    cargo build ${CARGO_FLAGS} --target ${CARGO_TARGET})

install -m644 $SOURCE_ROOT/kage-core/target/${CARGO_TARGET}/debug/libkage_core.dylib $OUT

nm -gU $OUT/libkage_core.dylib
