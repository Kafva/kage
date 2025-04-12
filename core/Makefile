.PHONY: clean cleanup_libs android ios

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
else
$(error Please build the `android' or `ios' target)
endif

android: $(DIST)/$(LIB)
ios: $(DIST)/$(LIB)

$(DIST)/$(LIB): cleanup_lib
	cd $(CURDIR) && cargo +stable rustc $(CARGO_RUSTC_FLAGS)
	mkdir -p $(dir $@)
	install -m644 $(CURDIR)/target/$(CARGO_TARGET)/release/$(LIB) $@

clean: cleanup_lib
	cd $(CURDIR) && cargo +stable clean

cleanup_lib:
	rm -f $(DIST)/$(LIB)
