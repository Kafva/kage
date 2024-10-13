.PHONY: clean cleanup_libs all

export PATH := $(HOME)/.cargo/bin:$(PATH)

ifeq ($(TARGET),ios) # iOS
# SOURCE_ROOT is set from Xcode to kage/ios, default to the same path
# when invoked manually.
SOURCE_ROOT ?= $(CURDIR)/../ios
LIB = libkage_core.a

PLATFORM_DISPLAY_NAME ?= iOS Simulator
CONFIGURATION ?= Debug

CARGO_CRATE_TYPE = staticlib
DIST = $(SOURCE_ROOT)/dist

ifeq ($(PLATFORM_DISPLAY_NAME),iOS Simulator)
ifeq ($(shell uname -m),x86_64)
CARGO_TARGET = x86_64-apple-ios
else
CARGO_TARGET = aarch64-apple-ios-sim
endif # uname -m

else ifeq ($(PLATFORM_DISPLAY_NAME),iOS)
CARGO_TARGET = aarch64-apple-ios
else
$(error Unsupported platform)
endif # PLATFORM_DISPLAY_NAME

ifeq ($(CONFIGURATION),Release)
# Disable default debug_logs feature
CARGO_FLAGS += --no-default-features
endif # CONFIGURATION

else ifeq ($(TARGET),android) # ANDROID

ifeq ($(NDK_HOME),)
$(error NDK_HOME is unset)
endif # NDK_HOME

SOURCE_ROOT = $(CURDIR)/../android
LIB = libkage_core.so

ANDROID_TARGET_ARCH ?= aarch64

CARGO_TARGET = $(ANDROID_TARGET_ARCH)-linux-android
CARGO_CRATE_TYPE = dylib

ifeq ($(ANDROID_TARGET_ARCH),aarch64)
DIST = $(SOURCE_ROOT)/src/main/jniLibs/arm64-v8a
else ifeq ($(ANDROID_TARGET_ARCH),x86_64)
DIST = $(SOURCE_ROOT)/src/main/jniLibs/x86_64
else
$(error Unsupported architecture: '$(ANDROID_TARGET_ARCH)')
endif # ANDROID_TARGET_ARCH

ifeq ($(shell uname -s),Darwin)
# There is no arm64 macOS toolchain
ANDROID_HOST_ARCH = darwin-x86_64
else
ANDROID_HOST_ARCH = linux-$(shell uname -m)
endif

ANDROID_CC = $(NDK_HOME)/toolchains/llvm/prebuilt/$(ANDROID_HOST_ARCH)/bin/$(ANDROID_TARGET_ARCH)-linux-android35-clang
ANDROID_AR = $(NDK_HOME)/toolchains/llvm/prebuilt/$(ANDROID_HOST_ARCH)/bin/llvm-ar

export CC_$(subst -,_,$(CARGO_TARGET)) = $(ANDROID_CC)
export AR_$(subst -,_,$(CARGO_TARGET)) = $(ANDROID_AR)

# $NDK_HOME is not expandable inside `.cargo/config.toml` so we provide it from
# here instead for now.
# https://github.com/rust-lang/cargo/issues/10789
CARGO_FLAGS += --config "target.$(CARGO_TARGET).linker='$(ANDROID_CC)'"
CARGO_FLAGS += --config "target.$(CARGO_TARGET).ar='$(ANDROID_AR)'"

else
$(error Please set TARGET to 'android' or 'ios')
endif # TARGET

CARGO_FLAGS += --lib
CARGO_FLAGS += --crate-type $(CARGO_CRATE_TYPE)
# Always build with --release when bundling for ffi, debug builds
# have issues on iOS.
CARGO_FLAGS += --release
CARGO_FLAGS += --target $(CARGO_TARGET)

################################################################################

all: $(DIST)/$(LIB)

$(DIST)/$(LIB): cleanup_libs
	cargo -Z unstable-options -C $(CURDIR) rustc $(CARGO_FLAGS)
	mkdir -p $(dir $@)
	install -m644 $(CURDIR)/target/$(CARGO_TARGET)/release/$(LIB) $@

clean: cleanup_libs
	cargo -Z unstable-options -C $(CURDIR) clean

cleanup_libs:
	rm -f $(DIST)/*.a $(DIST)/*.so $(DIST)/*.rlib
