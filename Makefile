# Always call `cargo` in case the XCODE_PLATFORM has changed
.PHONY: clean test $(LIB)

ARCH            := $(shell uname -m)
OUT             := $(CURDIR)/out
LIB             := $(OUT)/libkage_core.dylib
RUST_SRC        := $(wildcard ./kage-core/src/*.rs)
SWIFT_SRC       := $(wildcard ./ios/*.swift)

# Build for simulator unless XCODE_PLATFORM is explicitly passed
ifeq ("$(XCODE_PLATFORM)", "iOS")
CARGO_TARGET = aarch64-apple-ios
else ifeq ("$(ARCH)", "x86_64")
# x86_64 simulator
CARGO_TARGET = x86_64-apple-ios
CARGO_FLAGS += --features simulator
else
# arm64 simulator
CARGO_TARGET = aarch64-apple-ios-sim
CARGO_FLAGS += --features simulator
endif

$(LIB):
	$(info XCODE_PLATFORM=$(XCODE_PLATFORM))
	mkdir -p $(OUT)
	(cd kage-core && cargo build $(CARGO_FLAGS) --target $(CARGO_TARGET))
	install kage-core/target/$(CARGO_TARGET)/debug/$(notdir $(LIB)) $@
	nm -gU $@

clean:
	(cd kage-core && cargo clean)
	rm -rf $(OUT)

test:
	@echo Local git server needs to be running
	nc -zv 127.0.0.1 9418
	@# To show stdout/stderr: cargo test -- --nocapture
	(cd kage-core && cargo test)
