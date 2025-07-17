// SPDX‑License‑Identifier: MIT
//! *Internal* implementation of printing / housekeeping logic.
//!
//! All user‑facing ergonomics live in `lib.rs`; this module is **not**
//! re‑exported.  It produces no terminal output itself except via the `Write`
//! handle supplied by the caller.

use anyhow::{Context, Result};
use ignore::WalkBuilder;
use std::{
    fs,
    io::Write,
    path::Path,
};

/// Produce a directory tree beginning at `root`, honouring ignore patterns,
/// and write it to `writer`.
///
/// # Errors
///
/// Returns an error if:
/// - The root path cannot be written to the output
/// - I/O operations fail during tree generation
/// - The ignore file cannot be created or read
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

/// Remove every `.tree_ignore` file below `root`; returns the count.
///
/// *No user‑visible output — caller decides what to log.*
///
/// # Errors
///
/// Returns an error if:
/// - The root path cannot be accessed
/// - File removal operations fail
/// - Directory traversal encounters fatal errors
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
