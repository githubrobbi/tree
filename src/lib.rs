// SPDX‑License‑Identifier: MIT
// Copyright (c) 2025 Robert Nio

//! # Tree - Directory Tree Printer Library
//!
//! A fast, modern directory tree printer library written in Rust with configurable
//! ignore patterns and seamless `.gitignore` integration.
//!
//! ## Overview
//!
//! This library provides a clean, ergonomic API for generating directory tree
//! visualizations similar to the Unix `tree` command. It automatically respects
//! `.gitignore` files and supports custom `.tree_ignore` patterns for fine-grained
//! control over what gets displayed.
//!
//! ## Key Features
//!
//! - **Unicode tree rendering** with proper box-drawing characters
//! - **Automatic `.gitignore` integration** via the `ignore` crate
//! - **Custom ignore patterns** through `.tree_ignore` files
//! - **Memory efficient** streaming output to any `Write` sink
//! - **Zero panics** with comprehensive error handling
//! - **Cross-platform** support (Windows, macOS, Linux)
//!
//! ## Quick Start
//!
//! ```no_run
//! use std::io;
//! use tree::{print, clear, TreeError};
//!
//! // Print directory tree to stdout
//! let mut stdout = io::stdout();
//! print(std::path::Path::new("."), &mut stdout)?;
//!
//! // Clean up generated .tree_ignore files
//! let removed_count = clear(std::path::Path::new("."))?;
//! println!("Removed {} ignore files", removed_count);
//! # Ok::<(), TreeError>(())
//! ```
//!
//! ## Architecture
//!
//! The library is structured in two main layers:
//!
//! - **Public API** (`lib.rs`) - Path validation and error conversion
//! - **Core Implementation** (`tree_printer.rs`) - Tree rendering and file I/O
//!
//! This separation ensures a clean public interface while keeping implementation
//! details internal and allowing for future optimizations without breaking changes.
//!
//! ## Error Handling
//!
//! All operations return `Result<T, TreeError>` with structured error types that
//! provide clear context about what went wrong. The library never panics on
//! invalid input - all edge cases are handled gracefully.
//!
//! ## Performance
//!
//! The library uses streaming I/O and processes directories lazily, making it
//! suitable for large directory trees without excessive memory usage.

#![forbid(unsafe_code)]
#![deny(
    missing_docs,
    missing_debug_implementations,
    rust_2018_idioms,
    clippy::all,
    clippy::cargo,
    clippy::pedantic
)]

use std::path::Path;
use thiserror::Error;

/// Internal implementation — **NOT** part of the public API.
pub(crate) mod tree_printer;

/// Comprehensive error type for all tree operations.
///
/// This enum covers all possible failure modes when working with directory trees.
/// Each variant provides specific context about what went wrong, making debugging
/// and error handling straightforward.
///
/// ## Design Philosophy
///
/// - **Structured errors** - Each variant has semantic meaning
/// - **Rich context** - Error messages include the problematic path
/// - **Composable** - Integrates well with `?` operator and `Result` chains
/// - **User-friendly** - Error messages are suitable for end-user display
///
/// ## Examples
///
/// ```rust
/// use tree::{print, TreeError};
/// use std::io;
///
/// match print(std::path::Path::new("/nonexistent"), &mut io::stdout()) {
///     Ok(()) => println!("Tree printed successfully"),
///     Err(TreeError::PathMissing(path)) => eprintln!("Directory not found: {}", path),
///     Err(TreeError::NotADirectory(path)) => eprintln!("Not a directory: {}", path),
///     Err(TreeError::Io(io_err)) => eprintln!("I/O error: {}", io_err),
///     Err(TreeError::Other(err)) => eprintln!("Other error: {}", err),
/// }
/// ```
#[derive(Debug, Error)]
pub enum TreeError {
    /// The supplied path does not exist on the filesystem.
    ///
    /// This error occurs when attempting to process a directory that doesn't exist.
    /// The contained `String` is the display representation of the problematic path.
    #[error("Path `{0}` does not exist")]
    PathMissing(String),

    /// The supplied path exists but is not a directory.
    ///
    /// This error occurs when a file (or other non-directory) is passed where
    /// a directory is expected. The contained `String` is the display representation
    /// of the problematic path.
    #[error("Path `{0}` is not a directory")]
    NotADirectory(String),

    /// Any I/O-level failure during filesystem operations.
    ///
    /// This includes permission errors, disk full errors, network filesystem
    /// issues, and any other `std::io::Error` that might occur during directory
    /// traversal or file operations.
    #[error(transparent)]
    Io(#[from] std::io::Error),

    /// Catch-all for other internal errors.
    ///
    /// This handles any unexpected errors from internal operations, such as
    /// file format parsing errors or other edge cases. In practice, this should
    /// be rare in normal usage.
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

/// Print a directory hierarchy to any `Write` sink.
///
/// This is the primary function for generating directory tree visualizations.
/// It produces Unicode-formatted output similar to the Unix `tree` command,
/// with automatic `.gitignore` integration and support for custom ignore patterns.
///
/// ## Behavior
///
/// 1. **Validates the root path** - Ensures it exists and is a directory
/// 2. **Creates `.tree_ignore`** - Generates a default ignore file if none exists
/// 3. **Respects ignore patterns** - Honors both `.gitignore` and `.tree_ignore` files
/// 4. **Streams output** - Writes directly to the provided writer for memory efficiency
/// 5. **Unicode rendering** - Uses proper box-drawing characters for clean display
///
/// ## Output Format
///
/// ```text
/// /path/to/directory
/// ├── src/
/// │   ├── lib.rs
/// │   └── main.rs
/// ├── tests/
/// │   └── integration_tests.rs
/// └── Cargo.toml
/// ```
///
/// ## Examples
///
/// ```no_run
/// use std::io;
/// use tree::print;
///
/// // Print to stdout
/// let mut stdout = io::stdout();
/// print(std::path::Path::new("."), &mut stdout)?;
///
/// // Print to a string buffer
/// let mut buffer = Vec::new();
/// print(std::path::Path::new("./src"), &mut buffer)?;
/// let tree_output = String::from_utf8(buffer)?;
/// println!("Tree:\n{}", tree_output);
/// # Ok::<(), Box<dyn std::error::Error>>(())
/// ```
///
/// ## Performance
///
/// This function uses streaming I/O and lazy directory traversal, making it
/// suitable for large directory trees without excessive memory usage. The
/// ignore patterns are compiled once and reused throughout the traversal.
///
/// # Errors
///
/// Returns an error if:
/// - The root path does not exist ([`TreeError::PathMissing`])
/// - The root path is not a directory ([`TreeError::NotADirectory`])
/// - I/O operations fail during tree generation ([`TreeError::Io`])
/// - Internal operations encounter unexpected errors ([`TreeError::Other`])
pub fn print<W: std::io::Write>(root: &Path, writer: &mut W) -> Result<(), TreeError> {
    validate_root(root)?;
    tree_printer::print_directory_tree_to_writer(root, writer, true).map_err(TreeError::Other)
}

/// Generate and print a directory tree with display options.
///
/// This function provides more control over what gets displayed in the tree output.
/// It supports filtering between directories-only and full file/directory display.
///
/// # Arguments
///
/// * `root` - The root directory path to start tree generation from
/// * `writer` - Output destination implementing [`std::io::Write`]
/// * `show_files` - Whether to include files in the output (true) or directories only (false)
///
/// # Display Modes
///
/// * `show_files = true` - Shows both files and directories (default behavior)
/// * `show_files = false` - Shows only directories, files are omitted
///
/// # Examples
///
/// ```rust
/// use std::path::Path;
/// use tree::{print_with_options, TreeError};
///
/// fn main() -> Result<(), TreeError> {
///     // Show only directories
///     print_with_options(Path::new("."), &mut std::io::stdout(), false)?;
///
///     // Show files and directories (same as tree::print)
///     print_with_options(Path::new("."), &mut std::io::stdout(), true)?;
///
///     Ok(())
/// }
/// ```
///
/// # Errors
///
/// Returns an error if:
/// - The root path does not exist ([`TreeError::PathMissing`])
/// - The root path is not a directory ([`TreeError::NotADirectory`])
/// - I/O operations fail during tree generation ([`TreeError::Io`])
/// - Internal operations encounter unexpected errors ([`TreeError::Other`])
pub fn print_with_options<W: std::io::Write>(
    root: &Path,
    writer: &mut W,
    show_files: bool,
) -> Result<(), TreeError> {
    validate_root(root)?;
    tree_printer::print_directory_tree_to_writer(root, writer, show_files).map_err(TreeError::Other)
}

/// Remove every `.tree_ignore` file below the specified root directory.
///
/// This function recursively traverses the directory tree starting from `root`
/// and removes all `.tree_ignore` files it encounters. This is useful for
/// cleaning up after using the tree printer, especially in automated workflows
/// or when you want to reset ignore patterns.
///
/// ## Behavior
///
/// 1. **Validates the root path** - Ensures it exists and is a directory
/// 2. **Recursive traversal** - Walks through all subdirectories
/// 3. **Safe removal** - Only removes files named exactly `.tree_ignore`
/// 4. **Error resilience** - Continues processing even if some files can't be removed
/// 5. **Accurate counting** - Returns the exact number of files successfully removed
///
/// ## Use Cases
///
/// - **CI/CD cleanup** - Remove generated ignore files after builds
/// - **Development workflow** - Reset ignore patterns during development
/// - **Maintenance** - Clean up accumulated ignore files over time
/// - **Testing** - Ensure clean state between test runs
///
/// ## Examples
///
/// ```no_run
/// use tree::clear;
///
/// // Clean up current directory
/// match clear(std::path::Path::new(".")) {
///     Ok(count) => println!("Removed {} .tree_ignore files", count),
///     Err(e) => eprintln!("Failed to clear files: {}", e),
/// }
///
/// // Clean up specific project directory
/// let project_root = std::path::Path::new("./my-project");
/// let removed = clear(project_root)?;
/// if removed == 0 {
///     println!("No .tree_ignore files found");
/// } else {
///     println!("Cleaned up {} ignore files", removed);
/// }
/// # Ok::<(), tree::TreeError>(())
/// ```
///
/// ## Safety
///
/// This function only removes files with the exact name `.tree_ignore`. It will
/// never remove directories, symbolic links, or files with different names,
/// making it safe to run on any directory tree.
///
/// # Returns
///
/// Returns the number of `.tree_ignore` files successfully removed as a `u64`.
/// Files that couldn't be removed (due to permissions, etc.) are logged to
/// stderr but don't cause the function to fail.
///
/// # Errors
///
/// Returns an error if:
/// - The root path does not exist ([`TreeError::PathMissing`])
/// - The root path is not a directory ([`TreeError::NotADirectory`])
/// - Directory traversal fails due to permissions or I/O errors ([`TreeError::Io`])
/// - Internal operations encounter unexpected errors ([`TreeError::Other`])
pub fn clear(root: &Path) -> Result<u64, TreeError> {
    validate_root(root)?;
    tree_printer::clear_ignore_files_count(root).map_err(TreeError::Other)
}

/// Validates that a path exists and is a directory.
///
/// This is a common validation step used by both [`print`] and [`clear`] functions
/// to ensure the provided path is suitable for directory tree operations.
///
/// # Arguments
///
/// * `root` - The path to validate
///
/// # Returns
///
/// Returns `Ok(())` if the path exists and is a directory, otherwise returns
/// an appropriate [`TreeError`] variant.
///
/// # Errors
///
/// - [`TreeError::PathMissing`] if the path doesn't exist
/// - [`TreeError::NotADirectory`] if the path exists but isn't a directory
fn validate_root(root: &Path) -> Result<(), TreeError> {
    if !root.exists() {
        return Err(TreeError::PathMissing(root.display().to_string()));
    }
    if !root.is_dir() {
        return Err(TreeError::NotADirectory(root.display().to_string()));
    }
    Ok(())
}
