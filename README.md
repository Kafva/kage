# kage
iOS password manager with age-encryption and git.


## Development notes
```bash
# The serverdevel script sets up a git-daemon server and a repo that
# the client can use.
./scripts/serverdevel.sh

# To show stdout/stderr: cargo test -- --nocapture
(cd kage-core && cargo test)
```
