// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Robert Nio

//! Tree – directory tree printer
//!
//! A Rust library for printing directory trees with configurable ignore patterns.
//! This library provides a clean API for generating tree-like directory listings
//! while respecting `.gitignore` files and custom `.tree_ignore` patterns.
//!
//! # Features
//!
//! - Clean, formatted directory tree output
//! - Respects `.gitignore` files automatically
//! - Uses configurable `.tree_ignore` files for customizable ignore patterns
//! - Recursive clear functionality to remove all generated ignore files from directory trees
//! - Fast performance with Rust
//! - Simple API with structured error handling
//!
//! # Example
//!
//! ```rust
//! use std::path::Path;
//! use tree::{print, clear};
//!
//! // Print directory tree to stdout
//! let mut stdout = std::io::stdout();
//! print(Path::new("."), &mut stdout)?;
//!
//! // Clear all .tree_ignore files
//! let removed_count = clear(Path::new("."))?;
//! println!("Removed {} .tree_ignore files", removed_count);
//! # Ok::<(), tree::TreeError>(())
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

/// Tree printer module containing the core tree printing functionality
pub mod tree_printer;

/// Errors that can occur when using the tree library
#[derive(Error, Debug)]
pub enum TreeError {
    /// Path does not exist
    #[error("Path '{0}' does not exist")]
    PathMissing(String),

    /// Path exists but is not a directory
    #[error("Path '{0}' is not a directory")]
    NotADirectory(String),

    /// I/O error occurred during operation
    #[error(transparent)]
    Io(#[from] std::io::Error),

    /// Other error occurred
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

/// Print a directory tree to the specified writer
///
/// This function prints a formatted directory tree starting from the given root path.
/// It automatically creates a `.tree_ignore` file if one doesn't exist, and respects
/// both `.gitignore` and `.tree_ignore` patterns.
///
/// # Arguments
///
/// * `root` - The root directory path to start printing from
/// * `writer` - The writer to output the tree to (e.g., stdout, file, etc.)
///
/// # Returns
///
/// Returns `Ok(())` on success, or a `TreeError` if an error occurs.
///
/// # Errors
///
/// This function will return an error if:
/// - The root path does not exist
/// - The root path is not a directory
/// - An I/O error occurs during tree generation
///
/// # Example
///
/// ```rust
/// use std::path::Path;
/// use tree::print;
///
/// let mut output = Vec::new();
/// print(Path::new("."), &mut output)?;
/// let tree_output = String::from_utf8(output)?;
/// assert!(tree_output.contains("."));
/// # Ok::<(), Box<dyn std::error::Error>>(())
/// ```
pub fn print<W: std::io::Write>(root: &Path, writer: &mut W) -> Result<(), TreeError> {
    // Validate the path exists and is a directory
    if !root.exists() {
        return Err(TreeError::PathMissing(root.display().to_string()));
    }

    if !root.is_dir() {
        return Err(TreeError::NotADirectory(root.display().to_string()));
    }

    tree_printer::print_directory_tree_to_writer(root, writer).map_err(TreeError::Other)
}

/// Clear all `.tree_ignore` files from the specified directory tree
///
/// This function recursively searches through the directory tree starting from
/// the given root path and removes all `.tree_ignore` files it finds.
///
/// # Arguments
///
/// * `root` - The root directory path to start clearing from
///
/// # Returns
///
/// Returns the number of `.tree_ignore` files that were successfully removed,
/// or a `TreeError` if an error occurs.
///
/// # Errors
///
/// This function will return an error if:
/// - The root path does not exist
/// - The root path is not a directory
/// - An I/O error occurs during the clearing process
///
/// # Example
///
/// ```rust
/// use std::path::Path;
/// use tree::clear;
///
/// let removed_count = clear(Path::new("."))?;
/// println!("Removed {} .tree_ignore files", removed_count);
/// # Ok::<(), tree::TreeError>(())
/// ```
pub fn clear(root: &Path) -> Result<u64, TreeError> {
    // Validate the path exists and is a directory
    if !root.exists() {
        return Err(TreeError::PathMissing(root.display().to_string()));
    }

    if !root.is_dir() {
        return Err(TreeError::NotADirectory(root.display().to_string()));
    }

    tree_printer::clear_ignore_files_count(root).map_err(TreeError::Other)
}
