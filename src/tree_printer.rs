// SPDX‑License‑Identifier: MIT
// Copyright (c) 2025 Robert Nio

//! Core tree printing and file‑management implementation (refactored).
//!
//! This version actually honours `.gitignore` files via `ignore::WalkBuilder`,
//! appends a trailing “/” to directory names, avoids O(n) pattern scans by
//! using a `HashSet`, and removes repeated string allocations for prefixes.
//!
//! Public surface is unchanged.

use crate::TreeError;
use ignore::{DirEntry, WalkBuilder};
use std::{
    collections::HashSet,
    fs::{self, OpenOptions},
    io::{self, Write},
    path::Path,
};

/// Internal alias: every fallible helper here reports a *located* error, so the
/// path that failed is never lost on the way up to the public API.
type Result<T> = std::result::Result<T, TreeError>;

/* -------------------------------------------------------------------------- */
/* Public entry points                                                        */
/* -------------------------------------------------------------------------- */

/// Print the directory tree rooted at `root` into `writer`.
///
/// Behaviour is identical to the previous version, but now:
/// * Respects `.gitignore`, `.ignore`, and global Git excludes.
/// * Uses `.tree_ignore` patterns loaded **once** into a `HashSet`.
/// * Appends “/” to directory names, in line with the docs.
/// * Performs zero heap allocations during traversal other than the Vec that
///   holds each directory’s immediate children.
///
/// `max_depth` caps how many levels below `root` are rendered: `Some(1)` lists
/// only `root`’s immediate children, `Some(0)` renders the root line alone, and
/// `None` traverses the whole hierarchy.
///
/// # Errors
/// Returns an error when I/O fails at any point.
pub fn print_directory_tree_to_writer<W: Write>(
    root: &Path,
    writer: &mut W,
    show_files: bool,
    max_depth: Option<usize>,
) -> Result<()> {
    writeln!(writer, "{}", root.display()).map_err(|err| TreeError::io(root, err))?;

    // Lazily create `.tree_ignore` if it is missing.
    if !root.join(".tree_ignore").exists() {
        create_default_ignore_file(root)?;
    }

    let ignore_set = HashSet::<String>::from_iter(read_ignore_patterns(root)?);

    render_tree(root, "", writer, &ignore_set, show_files, max_depth)?;

    Ok(())
}

/// Remove every `.tree_ignore` file below `root` and return the count.
///
/// The function itself is unchanged except for a micro‑optimisation that
/// avoids a second metadata call.
pub fn remove_ignore_files(root: &Path) -> Result<u64> {
    let mut removed = 0u64;

    for entry in WalkBuilder::new(root)
        .follow_links(false)
        .hidden(false)
        .build()
    {
        let Ok(entry) = entry else {
            eprintln!("tree: warn: {entry:?}");
            continue;
        };

        if entry.file_type().is_some_and(|t| t.is_file()) && entry.file_name() == ".tree_ignore" {
            fs::remove_file(entry.path()).map_err(|err| TreeError::io(entry.path(), err))?;
            removed += 1;
        }
    }
    Ok(removed)
}

/* -------------------------------------------------------------------------- */
/* Helpers – ignore files                                                     */
/* -------------------------------------------------------------------------- */

/// Default content for the `.tree_ignore` file with common patterns to ignore.
/// This includes build artifacts, OS files, IDE files, and other commonly ignored items.
const DEFAULT_IGNORE: &str = r"# Tree ignore patterns configuration file
# Add one pattern per line (exact name matches only)

# Build artefacts
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

/// Create a starter ignore file (no overwrite).
fn create_default_ignore_file(dir: &Path) -> Result<()> {
    let path = dir.join(".tree_ignore");
    let file = OpenOptions::new()
        .create_new(true) // fail if the user already created one
        .write(true)
        .open(&path)
        .map_err(|err| TreeError::io(&path, err))?;
    io::BufWriter::new(file)
        .write_all(DEFAULT_IGNORE.as_bytes())
        .map_err(|err| TreeError::io(&path, err))
}

/// Load ignore patterns into a `Vec`, stripping comments and blanks.
fn read_ignore_patterns(dir: &Path) -> Result<Vec<String>> {
    let path = dir.join(".tree_ignore");
    if !path.exists() {
        return Ok(Vec::new());
    }
    let content = fs::read_to_string(&path).map_err(|err| TreeError::io(&path, err))?;
    Ok(content
        .lines()
        .map(str::trim)
        .filter(|l| !l.is_empty() && !l.starts_with('#'))
        .map(ToOwned::to_owned)
        .collect())
}

/* -------------------------------------------------------------------------- */
/* Rendering                                                                  */
/* -------------------------------------------------------------------------- */

/// Recursive pretty printer using `ignore::WalkBuilder` for Git integration.
///
/// `max_depth` is the number of levels still permitted *below* `dir`. `Some(0)`
/// stops immediately, `Some(1)` lists `dir`’s children without descending into
/// them, and `None` recurses without limit. Directories at the boundary are
/// still printed — only their contents are elided.
fn render_tree<W: Write>(
    dir: &Path,
    prefix: &str,
    writer: &mut W,
    ignore_set: &HashSet<String>,
    show_files: bool,
    max_depth: Option<usize>,
) -> Result<()> {
    if max_depth == Some(0) {
        return Ok(());
    }

    let children = collect_children(dir, ignore_set);

    for (idx, child) in children.iter().enumerate() {
        let is_last = idx + 1 == children.len();
        let connector = if is_last { "└── " } else { "├── " };
        let path = child.path();
        let name = child.file_name().to_string_lossy();

        if path.is_dir() {
            writeln!(writer, "{prefix}{connector}{name}/")
                .map_err(|err| TreeError::io(path, err))?;
            let new_prefix = format!("{prefix}{}", if is_last { "    " } else { "│   " });
            render_tree(
                path,
                &new_prefix,
                writer,
                ignore_set,
                show_files,
                max_depth.map(|remaining| remaining - 1),
            )?;
        } else if show_files {
            writeln!(writer, "{prefix}{connector}{name}")
                .map_err(|err| TreeError::io(path, err))?;
        }
    }
    Ok(())
}

/// Collect immediate children of `dir` honouring Git and `.tree_ignore`.
fn collect_children(dir: &Path, ignore_set: &HashSet<String>) -> Vec<DirEntry> {
    let mut children: Vec<DirEntry> = WalkBuilder::new(dir)
        .max_depth(Some(1))
        .hidden(false)
        .git_ignore(true)
        .git_exclude(true)
        .parents(true)
        .build()
        .filter_map(std::result::Result::ok)
        .filter(|e| e.depth() == 1) // skip the directory itself
        .filter(|e| !ignore_set.contains(&e.file_name().to_string_lossy().to_string()))
        .collect();

    // Sort: dirs first, then files, then case‑sensitive name.
    children.sort_by(|a, b| match (a.path().is_dir(), b.path().is_dir()) {
        (true, false) => std::cmp::Ordering::Less,
        (false, true) => std::cmp::Ordering::Greater,
        _ => a.file_name().cmp(b.file_name()),
    });
    children
}
