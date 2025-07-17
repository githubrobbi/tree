# Clippy Commands - Rust Master Approach

## Production Code (Ultra-Strict)
```bash
cargo clippy --lib --bins -- \
  -D clippy::pedantic \
  -D clippy::nursery \
  -D clippy::cargo \
  -A clippy::multiple_crate_versions \
  -W clippy::unwrap_used \
  -W clippy::expect_used \
  -W clippy::panic \
  -W clippy::missing_docs_in_private_items \
  -W clippy::todo \
  -W clippy::unimplemented \
  -D warnings
```

## Test Code (Pragmatic)
```bash
cargo clippy --tests -- \
  -D clippy::pedantic \
  -D clippy::nursery \
  -D clippy::cargo \
  -A clippy::multiple_crate_versions \
  -A clippy::unwrap_used \
  -A clippy::expect_used \
  -W clippy::panic \
  -W clippy::todo \
  -W clippy::unimplemented \
  -D warnings
```

## All Code (Current Command)
```bash
cargo clippy --workspace --all-targets --all-features -- \
  -D clippy::pedantic \
  -D clippy::nursery \
  -D clippy::cargo \
  -A clippy::multiple_crate_versions \
  -A clippy::unwrap_used \
  -A clippy::expect_used \
  -W clippy::panic \
  -W clippy::missing_docs_in_private_items \
  -W clippy::todo \
  -W clippy::unimplemented \
  -D warnings
```

## Philosophy
- **Production**: Bulletproof error handling
- **Tests**: Fast failure with clear stack traces
- **unwrap() in tests**: Actually preferred for debugging
