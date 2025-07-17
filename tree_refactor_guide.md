
# Transforming `tree` into a Rust Masterpiece 🌳

This document outlines a complete refactor and quality roadmap for your `tree` CLI tool written in Rust, based on the provided coverage reports and project files. It aims to elevate your codebase to a production-quality, idiomatic Rust project with robust tests, docs, and tooling.

---

## 📁 1. Project Structure

```
tree/
├── Cargo.toml
├── README.md
├── src
│   ├── lib.rs              # Library crate interface
│   ├── tree_printer.rs     # Internal module
│   └── bin
│       └── tree.rs         # CLI entry point
├── tests/                  # Integration tests
└── benches/                # Optional performance benchmarks
```

---

## 🧭 2. Crate Lints and Safety

In `lib.rs`, add:

```rust
#![forbid(unsafe_code)]
#![deny(
    missing_docs,
    missing_debug_implementations,
    rust_2018_idioms,
    clippy::all,
    clippy::cargo,
    clippy::pedantic
)]
```

---

## 🧩 3. Public API (`lib.rs`)

```rust
//! Tree – directory tree printer
//!
//! # Example
//! ```bash
//! tree
//! tree --clear /some/dir
//! ```

use std::path::Path;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum TreeError {
    #[error("`{0}` not found")]
    PathMissing(String),
    #[error("`{0}` is not a directory")]
    NotADirectory(String),
    #[error(transparent)]
    Io(#[from] std::io::Error),
}

pub fn print<W: std::io::Write>(root: &Path, writer: &mut W) -> Result<(), TreeError> {
    tree_printer::print_directory_tree(root, writer)
}

pub fn clear(root: &Path) -> Result<u64, TreeError> {
    tree_printer::clear_ignore_files(root)
}
```

---

## 🧪 4. Tests

| Layer       | Tool             | Purpose                                   |
|-------------|------------------|-------------------------------------------|
| Unit        | `#[cfg(test)]`   | Logic validation                          |
| Integration | `assert_cmd`     | CLI entry testing                         |
| Property    | `proptest`       | Edge case testing                         |
| Doc         | Rustdoc tests    | Live example verification                 |

---

## 🔧 5. CLI Binary (`src/bin/tree.rs`)

```rust
#[derive(clap::Parser)]
struct Cli {
    #[arg(default_value = ".")]
    path: PathBuf,

    #[arg(long, short = 'c')]
    clear: bool,
}

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();
    if cli.clear {
        let removed = tree::clear(&cli.path)?;
        println!("Removed {removed} file(s)");
    } else {
        tree::print(&cli.path, &mut std::io::stdout())?;
    }
    Ok(())
}
```

---

## 🎨 6. Extras

| Feature         | Crate        |
|-----------------|--------------|
| Color output    | `owo-colors` |
| Parallel walks  | `rayon` + `ignore` |
| Globs           | `globset`    |

---

## 📈 7. CI + Coverage

Use GitHub Actions to run:

```yaml
- run: cargo fmt --check
- run: cargo clippy --all-targets --all-features
- run: cargo test
- run: cargo llvm-cov --workspace --lcov --output-path lcov.info
```

---

## 📄 8. Licensing

Every source file must include:

```rust
// SPDX-License-Identifier: MPL-2.0 OR LicenseRef-TTAPI-Commercial
```

---

## 📦 9. Cargo.toml Enhancements

```toml
[package]
license = "MPL-2.0"
rust-version = "1.77"

[dependencies]
anyhow = "1"
ignore = "0.4"
walkdir = "2"
clap = { version = "4.5", features = ["derive"] }
thiserror = "1"

[dev-dependencies]
assert_cmd = "2"
predicates = "3"
proptest = "1"
```

---

## ✅ Final Checklist

- [ ] Migrate logic to `lib.rs`
- [ ] Enforce linting
- [ ] Cover missing lines (e.g., error branches in `clear_ignore_files`)
- [ ] Rustdoc examples with testable output
- [ ] Integration tests using temp dirs
- [ ] Public API with structured error type
- [ ] Dual license headers
- [ ] CI workflow with coverage and badges
