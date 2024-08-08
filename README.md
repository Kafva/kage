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
