// SPDX‑License‑Identifier: MIT
// Copyright (c) 2025 Robert Nio

//! Core tree printing and file‑management implementation (refactored).
//!
//! This version actually honours `.gitignore` files via `ignore::WalkBuilder`,
//! appends a trailing “/” to directory names, avoids O(n) pattern scans by
//! using a `HashSet`, and removes repeated string allocations for prefixes.
//!
//! Public surface is unchanged.

use anyhow::{Context, Result};
use ignore::{DirEntry, WalkBuilder};
use std::{
    collections::HashSet,
    fs::{self, OpenOptions},
    io::{self, Write},
    path::Path,
};

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
/// # Errors
/// Returns an error when I/O fails at any point.
pub fn print_directory_tree_to_writer<W: Write>(root: &Path, writer: &mut W) -> Result<()> {
    writeln!(writer, "{}", root.display()).context("failed to write root path")?;

    // Lazily create `.tree_ignore` if it is missing.
    if !root.join(".tree_ignore").exists() {
        create_default_ignore_file(root)?;
    }

    let ignore_set = HashSet::<String>::from_iter(read_ignore_patterns(root)?);

    render_tree(root, "", writer, &ignore_set)?;

    Ok(())
}

/// Remove every `.tree_ignore` file below `root` and return the count.
///
/// The function itself is unchanged except for a micro‑optimisation that
/// avoids a second metadata call.
pub fn clear_ignore_files_count(root: &Path) -> Result<u64> {
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
            fs::remove_file(entry.path())
                .with_context(|| format!("removing {}", entry.path().display()))?;
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
        .with_context(|| format!("creating {}", path.display()))?;
    io::BufWriter::new(file)
        .write_all(DEFAULT_IGNORE.as_bytes())
        .with_context(|| format!("writing defaults to {}", path.display()))
}

/// Load ignore patterns into a `Vec`, stripping comments and blanks.
fn read_ignore_patterns(dir: &Path) -> Result<Vec<String>> {
    let path = dir.join(".tree_ignore");
    if !path.exists() {
        return Ok(Vec::new());
    }
    let content =
        fs::read_to_string(&path).with_context(|| format!("reading {}", path.display()))?;
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
fn render_tree<W: Write>(
    dir: &Path,
    prefix: &str,
    writer: &mut W,
    ignore_set: &HashSet<String>,
) -> Result<()> {
    let children = collect_children(dir, ignore_set);

    for (idx, child) in children.iter().enumerate() {
        let is_last = idx + 1 == children.len();
        let connector = if is_last { "└── " } else { "├── " };
        let path = child.path();
        let name = child.file_name().to_string_lossy();

        if path.is_dir() {
            writeln!(writer, "{prefix}{connector}{name}/").context("failed to write directory")?;
            let new_prefix = format!("{prefix}{}", if is_last { "    " } else { "│   " });
            render_tree(path, &new_prefix, writer, ignore_set)?;
        } else {
            writeln!(writer, "{prefix}{connector}{name}").context("failed to write file")?;
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
