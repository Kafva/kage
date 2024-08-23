fn main() {
    let target = std::env::var("CARGO_BUILD_TARGET").unwrap_or_default();
    let configuration_ios = std::env::var("CONFIGURATION").unwrap_or_default();

    // Enable colored logs for all targets except non-simulator iOS devices
    if target != "aarch64-apple-ios" {
        println!("cargo:rustc-cfg=feature=\"color_logs\"");
    }

    // Enable debug logs for all targets except iOS release builds
    if configuration_ios != "Release" {
        println!("cargo:rustc-cfg=feature=\"debug_logs\"");
    }
}
