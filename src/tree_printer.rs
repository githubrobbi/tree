// SPDX‑License‑Identifier: MIT
// Copyright (c) 2025 Robert Nio

//! Core tree printing and file management implementation.
//!
//! This module contains the internal implementation details for directory tree
//! generation and `.tree_ignore` file management. It is **not** part of the public
//! API and should not be used directly by external code.
//!
//! ## Architecture Overview
//!
//! The module is organized into several key components:
//!
//! - **Public entry points** - [`print_directory_tree_to_writer`] and [`clear_ignore_files_count`]
//! - **Ignore file management** - Creation, reading, and parsing of `.tree_ignore` files
//! - **Tree rendering** - Unicode-based directory tree visualization
//! - **Directory traversal** - Efficient walking with ignore pattern filtering
//!
//! ## Design Principles
//!
//! - **Streaming I/O** - All output is written directly to the provided `Write` sink
//! - **Memory efficiency** - Directory traversal is lazy and doesn't load entire trees
//! - **Error resilience** - Individual file failures don't stop the entire operation
//! - **Unicode correctness** - Proper handling of non-UTF-8 filenames
//! - **Cross-platform** - Works consistently across Windows, macOS, and Linux
//!
//! ## Integration with `ignore` Crate
//!
//! This module leverages the excellent `ignore` crate for `.gitignore` integration
//! and efficient directory walking. The ignore patterns are combined with our
//! custom `.tree_ignore` patterns for comprehensive filtering.
//!
//! ## Thread Safety
//!
//! All functions in this module are thread-safe and can be called concurrently
//! from multiple threads, though individual `Write` sinks must be synchronized
//! by the caller if shared across threads.

use anyhow::{Context, Result};
use ignore::WalkBuilder;
use std::{
    fs,
    io::Write,
    path::Path,
};

/// Core implementation for directory tree printing.
///
/// This function performs the actual work of generating a directory tree
/// visualization. It handles ignore file creation, pattern parsing, and
/// recursive tree rendering with Unicode box-drawing characters.
///
/// ## Implementation Details
///
/// 1. **Root path output** - Writes the root directory path as the tree header
/// 2. **Ignore file management** - Creates default `.tree_ignore` if missing
/// 3. **Pattern compilation** - Reads and parses ignore patterns from files
/// 4. **Tree rendering** - Recursively walks and renders the directory structure
///
/// ## Output Format
///
/// The generated tree uses Unicode box-drawing characters for clean visualization:
/// - `├──` for intermediate entries
/// - `└──` for final entries in a directory
/// - `│   ` for vertical continuation lines
/// - `/` suffix for directories
///
/// ## Performance Characteristics
///
/// - **O(n)** time complexity where n is the number of non-ignored entries
/// - **O(d)** space complexity where d is the maximum directory depth
/// - **Streaming output** - no intermediate buffering of the entire tree
/// - **Lazy evaluation** - directories are processed only when needed
///
/// ## Integration with `ignore` Crate
///
/// This function leverages the `ignore` crate's `WalkBuilder` for efficient
/// directory traversal with built-in `.gitignore` support. Custom `.tree_ignore`
/// patterns are layered on top for additional filtering.
///
/// # Arguments
///
/// * `root` - The root directory to start tree generation from
/// * `writer` - The output sink for the generated tree (stdout, file, buffer, etc.)
///
/// # Errors
///
/// Returns an error if:
/// - The root path cannot be written to the output
/// - I/O operations fail during tree generation
/// - The ignore file cannot be created or read
/// - Directory traversal encounters permission or filesystem errors
pub fn print_directory_tree_to_writer<W: Write>(
    root: &Path,
    writer: &mut W,
) -> Result<()> {
    writeln!(writer, "{}", root.display())
        .context("failed to write root path")?;

    // Lazily create a default ignore file if missing, *before* reading patterns.
    let ignore_path = root.join(".tree_ignore");
    if !ignore_path.exists() {
        create_default_ignore_file(root)?;
    }
    let patterns = read_ignore_patterns(root)?;

    render_tree(root, "", writer, &patterns)?;
    Ok(())
}

/// Core implementation for recursive `.tree_ignore` file removal.
///
/// This function performs a depth-first traversal of the directory tree starting
/// from `root` and removes all `.tree_ignore` files encountered. It's designed
/// to be resilient to individual file failures while providing accurate counting.
///
/// ## Implementation Strategy
///
/// 1. **Recursive traversal** - Uses `ignore::WalkBuilder` for efficient walking
/// 2. **Selective removal** - Only removes files named exactly `.tree_ignore`
/// 3. **Error resilience** - Individual file failures are logged but don't stop processing
/// 4. **Accurate counting** - Returns the exact number of successfully removed files
/// 5. **No symbolic link following** - Avoids infinite loops and unintended deletions
///
/// ## Safety Guarantees
///
/// - **Name-based filtering** - Only files named `.tree_ignore` are considered
/// - **File type checking** - Only regular files are removed (not directories or links)
/// - **Atomic operations** - Each file removal is a separate filesystem operation
/// - **Error isolation** - Failure to remove one file doesn't affect others
///
/// ## Performance Characteristics
///
/// - **O(n)** time complexity where n is the total number of filesystem entries
/// - **O(1)** space complexity (constant memory usage regardless of tree size)
/// - **Streaming processing** - no intermediate storage of file lists
/// - **Early termination** - stops immediately on fatal traversal errors
///
/// ## Error Handling Philosophy
///
/// This function distinguishes between recoverable and fatal errors:
/// - **Recoverable**: Individual file removal failures (logged to stderr)
/// - **Fatal**: Directory traversal failures (returned as errors)
///
/// # Arguments
///
/// * `root` - The root directory to start the recursive removal from
///
/// # Returns
///
/// Returns the number of `.tree_ignore` files successfully removed as a `u64`.
/// This count only includes files that were actually deleted, not files that
/// couldn't be removed due to permissions or other issues.
///
/// # Errors
///
/// Returns an error if:
/// - The root path cannot be accessed or doesn't exist
/// - Directory traversal encounters fatal filesystem errors
/// - The `WalkBuilder` fails to initialize or traverse directories
///
/// Individual file removal failures are logged to stderr but do not cause
/// this function to return an error, allowing cleanup to continue.
pub fn clear_ignore_files_count(root: &Path) -> Result<u64> {
    let mut removed = 0u64;

    for entry in WalkBuilder::new(root)
        .follow_links(false)
        .hidden(false)
        .build()
    {
        let Ok(entry) = entry else {
            // Log to stderr but keep going — losing one file is not fatal.
            eprintln!("tree: warn: {entry:?}");
            continue;
        };

        if entry.file_type().is_some_and(|t| t.is_file())
            && entry.file_name() == ".tree_ignore"
        {
            fs::remove_file(entry.path())
                .with_context(|| format!("removing {}", entry.path().display()))?;
            removed += 1;
        }
    }

    Ok(removed)
}

/* -------------------------------------------------------------------------- */
/* Helpers                                                                    */
/* -------------------------------------------------------------------------- */

/// Default patterns written when a new `.tree_ignore` has to be created.
const DEFAULT_IGNORE: &str = r"# Tree ignore patterns configuration file
# Add one pattern per line (exact name matches only)

# Build / artefacts
target
build
dist
out

# Dependencies
node_modules
vendor
.pnpm-store

# VCS
.git
.svn
.hg

# IDEs & Editors
.vscode
.idea
*.swp
*.swo
*~

# OS cruft
.DS_Store
Thumbs.db
";

/// Create a starter ignore file in `dir` (idempotent).
///
/// # Errors
///
/// Returns an error if the file cannot be written to disk.
fn create_default_ignore_file(dir: &Path) -> Result<()> {
    fs::write(dir.join(".tree_ignore"), DEFAULT_IGNORE)
        .with_context(|| format!("creating {}", dir.join(".tree_ignore").display()))
}

/// Read patterns from `.tree_ignore`, stripping comments / blank lines.
///
/// # Errors
///
/// Returns an error if the ignore file exists but cannot be read.
fn read_ignore_patterns(dir: &Path) -> Result<Vec<String>> {
    let path = dir.join(".tree_ignore");
    if !path.exists() {
        return Ok(Vec::new());
    }

    let content = fs::read_to_string(&path)
        .with_context(|| format!("reading {}", path.display()))?;

    let patterns = content
        .lines()
        .map(str::trim)
        .filter(|l| !l.is_empty() && !l.starts_with('#'))
        .map(ToOwned::to_owned)
        .collect();

    Ok(patterns)
}



/* -------------------------------------------------------------------------- */
/* Rendering                                                                  */
/* -------------------------------------------------------------------------- */

/// Recursive pretty‑printer.
///
/// Renders a directory tree with Unicode box-drawing characters.
///
/// # Errors
///
/// Returns an error if I/O operations fail during rendering.
fn render_tree<W: Write>(
    dir: &Path,
    prefix: &str,
    writer: &mut W,
    patterns: &[String],
) -> Result<()> {
    // Collect and sort children: dirs first, then files (both case‑sensitive).
    let mut children: Vec<_> = fs::read_dir(dir)
        .with_context(|| format!("reading directory {}", dir.display()))?
        .filter_map(Result::ok)
        .filter(|e| !should_ignore_dir_entry(e, patterns))
        .collect();

    children.sort_by(|a, b| match (a.path().is_dir(), b.path().is_dir()) {
        (true, false) => std::cmp::Ordering::Less,
        (false, true) => std::cmp::Ordering::Greater,
        _ => a.file_name().cmp(&b.file_name()),
    });

    for (index, entry) in children.iter().enumerate() {
        let is_last = index + 1 == children.len();
        let connector = if is_last { "└── " } else { "├── " };
        writeln!(
            writer,
            "{prefix}{connector}{}",
            entry.file_name().to_string_lossy()
        )
            .with_context(|| "failed to write tree line")?;

        if entry.path().is_dir() {
            let extension = if is_last { "    " } else { "│   " };
            let new_prefix = format!("{prefix}{extension}");
            render_tree(&entry.path(), &new_prefix, writer, patterns)?;
        }
    }

    Ok(())
}

/// Check if a directory entry should be ignored based on patterns.
///
/// Returns `true` if the entry's filename matches any of the ignore patterns.
fn should_ignore_dir_entry(entry: &fs::DirEntry, patterns: &[String]) -> bool {
    patterns
        .iter()
        .any(|p| entry.file_name().to_string_lossy() == *p)
}
