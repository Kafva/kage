LIB=libkage_core.dylib
RUST_SRC=kage-core/src

TARGET=aarch64-apple-ios-sim

all: out/$(LIB)

out/$(LIB): $(RUST_SRC)
	mkdir -p ./out
	cd kage-core; \
		cargo build --target $(TARGET)
	install kage-core/target/$(TARGET)/debug/$(LIB) $@
