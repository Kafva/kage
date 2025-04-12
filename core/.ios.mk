# Xcode sets SOURCE_ROOT, PLATFORM_DISPLAY_NAME, CONFIGURATION etc.
SOURCE_ROOT ?= $(CURDIR)/../ios
PLATFORM_DISPLAY_NAME ?= iOS Simulator
CONFIGURATION ?= Debug

CARGO_CRATE_TYPE = staticlib
DIST = $(SOURCE_ROOT)/dist
LIB = libkage_core.a

ifeq ($(PLATFORM_DISPLAY_NAME),iOS Simulator)

ifeq ($(shell uname -m),x86_64)
CARGO_TARGET = x86_64-apple-ios
else
CARGO_TARGET = aarch64-apple-ios-sim
endif

else ifeq ($(PLATFORM_DISPLAY_NAME),iOS)
CARGO_TARGET = aarch64-apple-ios

else
$(error Unsupported platform)

endif # PLATFORM_DISPLAY_NAME

ifeq ($(CONFIGURATION),Release)
# Disable default debug_logs feature for release builds
CARGO_RUSTC_FLAGS += --no-default-features
endif
