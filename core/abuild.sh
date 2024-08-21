#!/usr/bin/env bash
set -eu

#
# Build script for Android
#

CURDIR=$(cd "$(dirname $0)" && pwd)
# Path to android folder
SOURCE_ROOT=${SOURCE_ROOT:-"${CURDIR}/../android"}

PATH="$PATH:$HOME/.cargo/bin"
LIB="libkage_core.a"
DIST=$SOURCE_ROOT/app/src/main/jniLibs/arm64-v8a

CARGO_BUILDTYPE=release
rm -f "$DIST/*.{so,rlib,a}"

# TODO hardcoded for one Android target platform
CARGO_TARGET=aarch64-linux-android
# export LD_aarch64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android35-clang"
# export CC_aarch64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android35-clang"
# export AR_aarch64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar"

# XXX full rebuild
rm -rf $SOURCE_ROOT/../core/target/$CARGO_TARGET

# https://github.com/rust-lang/cargo/issues/12260
cargo \
    -Z unstable-options \
    -C $SOURCE_ROOT/../core \
    rustc \
    --lib \
    --crate-type dylib \
    --release \
    --target ${CARGO_TARGET}

# Always copy the output for the current platform to dist
mkdir -p "$DIST"
cp "$SOURCE_ROOT/../core/target/${CARGO_TARGET}/${CARGO_BUILDTYPE}/$LIB" \
   "$DIST/$LIB"
