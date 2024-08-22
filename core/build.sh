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
    if [ -z "$NDK_HOME" ]; then
        echo "NDK_HOME is unset" >&2
        exit 1
    fi

    SOURCE_ROOT=${SOURCE_ROOT:-"${CURDIR}/../android"}

    LIB="libkage_core.so"
    CARGO_CRATE_TYPE=dylib
    # XXX: Hardcoded target ABI
    DIST=$SOURCE_ROOT/app/src/main/jniLibs/arm64-v8a
    CARGO_TARGET=aarch64-linux-android

    name="${CARGO_TARGET//-/_}"
    export "CC_${name}"="$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android35-clang"
    export "AR_${name}"="$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar"

    # $NDK_HOME is not expandable inside `.cargo/config.toml` so we provide it from
    # here instead for now.
    # https://github.com/rust-lang/cargo/issues/10789
    CARGO_EXTRA_FLAGS=(
       --config
       "target.$CARGO_TARGET.ar='$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar'"
       --config
       "target.$CARGO_TARGET.linker='$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android35-clang'"
    )
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

    CARGO_EXTRA_FLAGS=()
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
    ${CARGO_EXTRA_FLAGS[@]} \
    --target ${CARGO_TARGET}

# Always copy the output for the current platform to dist
mkdir -p "$DIST"
cp -v "$SOURCE_ROOT/../core/target/${CARGO_TARGET}/${CARGO_BUILDTYPE}/$LIB" \
      "$DIST/$LIB"
