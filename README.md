# kage
Password manager for mobile (iOS and Android) using age-encryption and git.
The layout of the git repository that kage expects can be setup with:
```bash
tools/repoinit $NAME
```

Only the iOS version supports modifying the password store on device, for
Android all changes to the password store are made remotely and fetched.

To use the password store on macOS/Linux etc. you can write a basic
wrapper yourself or use [passage](https://github.com/FiloSottile/passage):

```bash
PASSAGE_DIR=$NAME PASSAGE_IDENTITIES_FILE=$NAME/.age-identities passage
```

## Development notes
A git server for automated and manual testing can be setup with
[scripts/serverdevel](scripts/serverdevel). To run the automated tests:

### Core library
```bash
# Start git-daemon for unit tests
./tools/serverdevel -d unit

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

### iOS
Unit tests can be ran from within Xcode, the tests expect the development
server to be running on localhost
```bash
./tools/serverdevel -d unit
```

### Android
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
