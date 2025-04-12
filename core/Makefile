.PHONY: clean cleanup_libs android ios

CARGO = cargo +stable
CARGO_RUSTC_FLAGS = --lib
# Always build with --release when bundling for ffi, debug builds
# have issues on iOS.
CARGO_RUSTC_FLAGS += --release
CARGO_RUSTC_FLAGS += --crate-type $(CARGO_CRATE_TYPE)
CARGO_RUSTC_FLAGS += --target $(CARGO_TARGET)

ifeq ($(filter ios,$(MAKECMDGOALS)),ios)
include .ios.mk
else ifeq ($(filter android,$(MAKECMDGOALS)),android)
include .android.mk
endif

android: $(DIST)/$(LIB)
ios: $(DIST)/$(LIB)

$(DIST)/$(LIB): cleanup_lib
	cd $(CURDIR) && $(CARGO) rustc $(CARGO_RUSTC_FLAGS)
	mkdir -p $(dir $@)
	install -m644 $(CURDIR)/target/$(CARGO_TARGET)/release/$(LIB) $@

test:
	cd $(CURDIR) && $(CARGO) test

clean: cleanup_lib
	cd $(CURDIR) && $(CARGO) clean

cleanup_lib:
	rm -f $(DIST)/$(LIB)
