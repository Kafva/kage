<p align="center">
  <img src="https://github.com/user-attachments/assets/44d91fdd-a53a-45a2-b5e5-11286edb1f10" width=128 height=128 />
</p>

<h1 align="center">kage</h1>

Password manager for iOS and Android using age-encryption and git.
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

The client only fetches passwords over `git://`:
```bash
git daemon --base-path="$NAME" \
           --verbose \
           --export-all \
           --reuseaddr \
           --informative-errors
```
To enable anonymous pushing(!) pass `--enable=receive-pack`, this is not
relevant for the Android client since it does not support making local changes.

Note: all password files named `otp.age` will be treated as encrypted
`otpauth://` URLs and kage will automatically try to resolve them into a
time-based one time password (TOTP).

## Development notes

### Core library
```bash
# Start git-daemon for unit tests
./tools/serverdevel -d unit

# Run tests
make -C core test

# Note: the test cases run in parallel, this sometimes causes random failures on macOS:
#   error receiving data from socket: Connection reset by peer; class=Net (12)

# Run tests with coverage information
cargo install cargo-llvm-cov
rustup component add llvm-tools-preview
(cd core && cargo llvm-cov --html)
```

### iOS
1. Download stable rust toolchain
```bash
rustup target add --toolchain stable aarch64-apple-ios
rustup target add --toolchain stable aarch64-apple-ios-sim
```
2. Build from Xcode or with `xcodebuild`

Unit tests can be ran from within Xcode, the tests expect the development
server to be running on localhost
```bash
./tools/serverdevel -d unit
```

### Android
1. Download stable rust toolchain
```bash
rustup target add --toolchain stable aarch64-linux-android
```
2. Download the Android NDK: `sdkmanager 'ndk;$VERSION'`
3. Set `export NDK_HOME=$HOME/Library/Android/Sdk/ndk/$VERSION` (macOS)
4. Build the library and app

```bash
# Make sure the library is built for all archs *before* creating the APK
ANDROID_TARGET_ARCH=aarch64 make -C core android
ANDROID_TARGET_ARCH=x86_64 make -C core android
(cd android && ./tools/genkey.sh)
(cd android && ./gradlew build assembleRelease)
# => android/build/outputs/apk/release/kage-release.apk
```
