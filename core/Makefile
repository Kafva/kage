CARGO = cargo +stable
CARGO_RUSTC_FLAGS = --lib
# Always build with --release when bundling for ffi, debug builds
# have issues on iOS.
CARGO_RUSTC_FLAGS += --release
CARGO_RUSTC_FLAGS += --crate-type $(CARGO_CRATE_TYPE)
CARGO_RUSTC_FLAGS += --target $(CARGO_TARGET)

IOS_LIB = libkage_core.a
ANDROID_LIB = libkage_core.so

ifeq ($(filter ios,$(MAKECMDGOALS)),ios)
include .ios.mk
else ifeq ($(filter android,$(MAKECMDGOALS)),android)
include .android.mk
else ifneq ($(filter test,$(MAKECMDGOALS)),test)
ifneq ($(filter clean,$(MAKECMDGOALS)),clean)
$(error Please pick the `ios' or `android' target)
endif
endif

android: $(DIST)/$(LIB)
ios: $(DIST)/$(LIB)

$(DIST)/$(LIB): $(wildcard src/*.rs)
	cd $(CURDIR) && $(CARGO) rustc $(CARGO_RUSTC_FLAGS)
	mkdir -p $(dir $@)
	install -m644 $(CURDIR)/target/$(CARGO_TARGET)/release/$(LIB) $@

test:
	@# To show stdout/stderr: cargo test -- --nocapture
	cd $(CURDIR) && $(CARGO) test

clean:
	find $(CURDIR)/.. -name $(IOS_LIB) -exec rm -v {} \;
	find $(CURDIR)/.. -name $(ANDROID_LIB) -exec rm -v {} \;
	cd $(CURDIR) && $(CARGO) clean
