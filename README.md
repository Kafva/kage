# kage
iOS password manager with age-encryption and git.


## Development notes
A git server for automated and manual testing can be setup with
[scripts/serverdevel.sh](/scripts/serverdevel.sh). To run the automated tests:

```bash
./scripts/serverdevel.sh unit

# To show stdout/stderr: cargo test -- --nocapture
(cd kage-core && cargo test)
```
