# kage
iOS password manager with age-encryption and git.


## Development notes
A git server for automated and manual testing can be setup with
[scripts/serverdevel.sh](scripts/serverdevel.sh). To run the automated tests:

```bash
# Start git-daemon for unit tests
./tools/serverdevel.sh unit

# To show stdout/stderr: cargo test -- --nocapture
(cd core && cargo test)

# To debug a testcase
cd core &&
cargo test --no-run &&
    rust-lldb $(fd '^kage_core-[0-9a-z]{16}$' target/debug/deps) -- $testcase

# Run tests with coverage information
cargo install cargo-llvm-cov
rustup component add llvm-tools-preview
(cd core && cargo llvm-cov --html)
```

## Android
The build process has only been tested to work on macOS.
To build for Android you need to download a NDK manually.

1. Download the ndk: `sdkmanager 'ndk;$VERSION'`
2. Make sure `android/app/build.gradle.kts` points to the same version
3. Set `export NDK_HOME=$HOME/Library/Android/Sdk/ndk/$VERSION`
4. Build the library and app

```bash
core/build.sh android
(cd android && ./gradlew :app:assembleRelease)
```
