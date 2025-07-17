// SPDX‑License‑Identifier: MIT
//! Public API for the *tree* crate.
//
//! ```no_run
//! use std::path::Path;
//! use tree::{print, clear, TreeError};
//!
//! // print the directory tree
//! print(Path::new("."), &mut std::io::stdout()).unwrap();
//!
//! // remove every `.tree_ignore` file
//! let removed = clear(Path::new("."))?;
//! println!("Removed {removed} .tree_ignore file(s)");
//! # Ok::<(), TreeError>(())
//! ```

#![forbid(unsafe_code)]
#![deny(
    missing_docs,
    missing_debug_implementations,
    rust_2018_idioms,
    clippy::all,
    clippy::cargo,
    clippy::pedantic
)]
#![allow(clippy::module_name_repetitions)]

use std::path::Path;
use thiserror::Error;

/// Internal implementation — **NOT** part of the public API.
pub(crate) mod tree_printer;

/// Errors produced by this crate.
#[derive(Debug, Error)]
pub enum TreeError {
    /// The supplied path does not exist.
    #[error("Path `{0}` does not exist")]
    PathMissing(String),

    /// The supplied path exists but is not a directory.
    #[error("Path `{0}` is not a directory")]
    NotADirectory(String),

    /// Any I/O‑level failure.
    #[error(transparent)]
    Io(#[from] std::io::Error),

    /// Catch‑all for other errors.
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

/// Print a directory hierarchy to any `Write` sink.
///
/// This is a thin, path‑validating wrapper around the internal printer.
///
/// *Never* writes to stdout/stderr itself.
///
/// # Errors
///
/// Returns an error if:
/// - The root path does not exist
/// - The root path is not a directory
/// - I/O operations fail during tree generation
pub fn print<W: std::io::Write>(
    root: &Path,
    writer: &mut W,
) -> Result<(), TreeError> {
    validate_root(root)?;
    tree_printer::print_directory_tree_to_writer(root, writer).map_err(TreeError::Other)
}

/// Remove every `.tree_ignore` file below `root`.
/// Returns the number of files removed.
///
/// # Errors
///
/// Returns an error if:
/// - The root path does not exist
/// - The root path is not a directory
/// - File removal operations fail
pub fn clear(root: &Path) -> Result<u64, TreeError> {
    validate_root(root)?;
    tree_printer::clear_ignore_files_count(root).map_err(TreeError::Other)
}

/// Common path sanity checks.
fn validate_root(root: &Path) -> Result<(), TreeError> {
    if !root.exists() {
        return Err(TreeError::PathMissing(root.display().to_string()));
    }
    if !root.is_dir() {
        return Err(TreeError::NotADirectory(root.display().to_string()));
    }
    Ok(())
}
