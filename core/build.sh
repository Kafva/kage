#!/usr/bin/env bash
set -e

#
# Build script for iOS and Android
#

die() { printf "$1\n" >&2 && exit 1; }
usage() {
    cat << EOF >&2
usage: $(basename $0) <android|ios> [android target arch]
EOF
    exit 1
}

CURDIR=$(cd "$(dirname $0)" && pwd)
PATH="$HOME/.cargo/bin:$PATH"

case "$1" in
android)
    if [ -z "$NDK_HOME" ]; then
        echo "NDK_HOME is unset" >&2
        exit 1
    fi

    SOURCE_ROOT=${SOURCE_ROOT:-"${CURDIR}/../android"}
    TARGET_ARCH=${2:-"aarch64"}

    if [ "$TARGET_ARCH" = aarch64 ]; then
        DIST=$SOURCE_ROOT/src/main/jniLibs/arm64-v8a

    elif [ "$TARGET_ARCH" = x86_64 ]; then
        DIST=$SOURCE_ROOT/src/main/jniLibs/x86_64

    else
        die "Unsupported architecture: '$TARGET_ARCH'"
    fi

    LIB="libkage_core.so"
    CARGO_CRATE_TYPE=dylib
    CARGO_TARGET=$TARGET_ARCH-linux-android

    name="${CARGO_TARGET//-/_}"
    case "$(uname)" in
    # There is no arm64 macOS toolchain
    Darwin) llvm_toolchain_arch=darwin-x86_64 ;;
    Linux) llvm_toolchain_arch="linux-$(uname -m)" ;;
    esac

    llvm_cc="$NDK_HOME/toolchains/llvm/prebuilt/$llvm_toolchain_arch/bin/$TARGET_ARCH-linux-android35-clang"
    llvm_ar="$NDK_HOME/toolchains/llvm/prebuilt/$llvm_toolchain_arch/bin/llvm-ar"

    export "CC_${name}"="$llvm_cc"
    export "AR_${name}"="$llvm_ar"

    # $NDK_HOME is not expandable inside `.cargo/config.toml` so we provide it from
    # here instead for now.
    # https://github.com/rust-lang/cargo/issues/10789
    CARGO_EXTRA_FLAGS=(
       --config
       "target.$CARGO_TARGET.linker='$llvm_cc'"
       --config
       "target.$CARGO_TARGET.ar='$llvm_ar'"
    )
;;
ios)
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
*)
    usage
esac

if [ "$CONFIGURATION" = Release ]; then
    # Disable default debug_logs feature
    CARGO_EXTRA_FLAGS+=(--no-default-features)
fi

rm -f "$DIST/*.{a,so,rlib}"

# Always build with --release when bundling for ffi, debug builds
# have issues on iOS.
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
cp -v "$SOURCE_ROOT/../core/target/${CARGO_TARGET}/release/$LIB" \
      "$DIST/$LIB"
