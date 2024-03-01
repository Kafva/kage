.PHONY: clean test

ARCH            := $(shell uname -m)
LIB             := libkage_core.dylib
RUST_SRC        := $(wildcard ./kage-core/src/*.rs)
SWIFT_SRC       := $(wildcard ./ios/*.swift)
OUT             := $(CURDIR)/out

# Build for simulator unless XCODE_PLATFORM is explicitly passed
ifeq ("$(XCODE_PLATFORM)", "iOS")
RUST_TARGET = aarch64-apple-ios
else ifeq ("$(ARCH)", "x86_64")
# x86_64 simulator
RUST_TARGET = x86_64-apple-ios
RUST_FLAGS += --feature simulator
else
# arm64 simulator
RUST_TARGET = aarch64-apple-ios-sim
RUST_FLAGS += --feature simulator
endif

all: $(OUT)/$(LIB)

$(OUT)/$(LIB): $(RUST_SRC) $(SWIFT_SRC)
	$(info XCODE_PLATFORM=$(XCODE_PLATFORM))
	mkdir -p $(OUT)
	(cd kage-core && cargo build $(RUST_FLAGS) --target $(RUST_TARGET))
	install kage-core/target/$(RUST_TARGET)/debug/$(LIB) $@
	nm -gU $@

clean:
	(cd kage-core && cargo clean)
	rm -rf $(OUT)

test:
	@echo Local git server needs to be running
	nc -zv 127.0.0.1 9418
	@# To show stdout/stderr: cargo test -- --nocapture
	(cd kage-core && cargo test)
