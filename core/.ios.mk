# Xcode sets: TARGET_DEVICE_PLATFORM_NAME and CONFIGURATION.
# These need to be passed from the build script!
TARGET_DEVICE_PLATFORM_NAME ?= iphonesimulator
CONFIGURATION ?= Debug

CARGO_CRATE_TYPE = staticlib
DIST = $(CURDIR)/../ios/dist
LIB = $(IOS_LIB)

ifeq ($(TARGET_DEVICE_PLATFORM_NAME),iphonesimulator)

ifeq ($(shell uname -m),x86_64)
CARGO_TARGET = x86_64-apple-ios
else
CARGO_TARGET = aarch64-apple-ios-sim
endif

else ifeq ($(TARGET_DEVICE_PLATFORM_NAME),iphoneos)
CARGO_TARGET = aarch64-apple-ios

else
$(error Unsupported platform)

endif # TARGET_DEVICE_PLATFORM_NAME

ifeq ($(CONFIGURATION),Release)
# Disable default debug_logs feature for release builds
CARGO_RUSTC_FLAGS += --no-default-features
endif
