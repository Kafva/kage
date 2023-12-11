LIB=libkage_core.dylib
RUST_SRC=$(wildcard ./kage-core/src/*.rs)
SWIFT_SRC=$(wildcard ./ios/*.swift)

# XXX: Default to simulator compatible build
ifeq ("$(XCODE_PLATFORM)", "iOS")
	RUST_TARGET=aarch64-apple-ios
else
	RUST_TARGET=aarch64-apple-ios-sim
endif

all: ./out/$(LIB)

./out/$(LIB): $(RUST_SRC) $(SWIFT_SRC)
	$(info XCODE_PLATFORM=$(XCODE_PLATFORM))
	mkdir -p ./out
	cd kage-core; \
		cargo build --target $(RUST_TARGET)
	install kage-core/target/$(RUST_TARGET)/debug/$(LIB) $@
	nm -gU $@

clean:
	rm -rf ./out
