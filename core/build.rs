fn main() {
    let target = std::env::var("CARGO_BUILD_TARGET").unwrap_or_default();

    // Enable colored logs for all targets except non-simulator iOS devices
    if target != "aarch64-apple-ios" {
        println!("cargo:rustc-cfg=feature=\"color_logs\"");
    }
}
