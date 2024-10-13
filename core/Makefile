.PHONY: clean cleanup_libs all

# Make sure we find `cargo'
export PATH := $(HOME)/.cargo/bin:$(PATH)

CARGO_RUSTC_FLAGS = --lib
# Always build with --release when bundling for ffi, debug builds
# have issues on iOS.
CARGO_RUSTC_FLAGS += --release
CARGO_RUSTC_FLAGS += --crate-type $(CARGO_CRATE_TYPE)
CARGO_RUSTC_FLAGS += --target $(CARGO_TARGET)

ifeq ($(TARGET),ios)
include .ios.mk
else ifeq ($(TARGET),android)
include .android.mk
else
$(error Please set TARGET to 'android' or 'ios')
endif

all: $(DIST)/$(LIB)

# `-C' is an unstable option
$(DIST)/$(LIB): cleanup_libs
	cargo -Z unstable-options -C $(CURDIR) rustc $(CARGO_RUSTC_FLAGS)
	mkdir -p $(dir $@)
	install -m644 $(CURDIR)/target/$(CARGO_TARGET)/release/$(LIB) $@

clean: cleanup_libs
	cargo -Z unstable-options -C $(CURDIR) clean

cleanup_libs:
	rm -f $(DIST)/*.a $(DIST)/*.so $(DIST)/*.rlib
