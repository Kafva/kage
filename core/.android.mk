ifeq ($(NDK_HOME),)
$(error NDK_HOME is unset)
endif # NDK_HOME

SOURCE_ROOT = $(CURDIR)/../android
ANDROID_TARGET_ARCH ?= $(shell adb shell uname -m 2> /dev/null)
ifeq ($(ANDROID_TARGET_ARCH),)
ANDROID_TARGET_ARCH = aarch64
endif

CARGO_CRATE_TYPE = dylib
LIB = $(ANDROID_LIB)

CARGO_TARGET = $(ANDROID_TARGET_ARCH)-linux-android

ifeq ($(ANDROID_TARGET_ARCH),aarch64)
DIST = $(SOURCE_ROOT)/build/jniLibs/arm64-v8a

else ifeq ($(ANDROID_TARGET_ARCH),x86_64)
DIST = $(SOURCE_ROOT)/build/jniLibs/x86_64

else
$(error Unsupported architecture: '$(ANDROID_TARGET_ARCH)')

endif # ANDROID_TARGET_ARCH

ifeq ($(shell uname -s),Darwin)
# There is no arm64 macOS toolchain
ANDROID_HOST_ARCH = darwin-x86_64
else
ANDROID_HOST_ARCH = linux-$(shell uname -m)
endif

ANDROID_BINDIR = $(NDK_HOME)/toolchains/llvm/prebuilt/$(ANDROID_HOST_ARCH)/bin
ANDROID_CC = $(ANDROID_BINDIR)/$(ANDROID_TARGET_ARCH)-linux-android35-clang
ANDROID_AR = $(ANDROID_BINDIR)/llvm-ar

export CC_$(subst -,_,$(CARGO_TARGET)) = $(ANDROID_CC)
export AR_$(subst -,_,$(CARGO_TARGET)) = $(ANDROID_AR)

# $NDK_HOME is not expandable inside `.cargo/config.toml` so we provide it from
# here instead for now.
# https://github.com/rust-lang/cargo/issues/10789
CARGO_RUSTC_FLAGS += --config "target.$(CARGO_TARGET).linker='$(ANDROID_CC)'"
CARGO_RUSTC_FLAGS += --config "target.$(CARGO_TARGET).ar='$(ANDROID_AR)'"
