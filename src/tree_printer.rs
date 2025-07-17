// =============================================================================
// src/tree_printer.rs
// =============================================================================
//
// SPDX-License-Identifier: MPL-2.0 OR LicenseRef-TTAPI-Commercial
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 SKY, LLC.
//
// TTAPI - Tastytrade API High-Performance Options Trading Platform
// Contact: skylegal@nios.net for licensing inquiries
//

use std::collections::HashSet;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use ignore::{DirEntry, WalkBuilder};

/// Function to check if a directory or file should be ignored based on provided patterns
fn should_ignore(entry: &DirEntry, ignore_patterns: &[String]) -> bool {
    entry.file_name().to_str().is_some_and(|file_name| ignore_patterns.iter().any(|pattern| pattern == file_name))
}

/// Read ignore patterns from `.tree_ignore` file
fn read_ignore_patterns<P: AsRef<Path>>(base_path: P) -> Result<Vec<String>> {
    let ignore_file_path = base_path.as_ref().join(".tree_ignore");

    if !ignore_file_path.exists() {
        return Ok(Vec::new());
    }

    let content = fs::read_to_string(&ignore_file_path)
        .with_context(|| format!("Failed to read ignore file: {}", ignore_file_path.display()))?;

    let patterns: Vec<String> = content
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .map(std::string::ToString::to_string)
        .collect();

    Ok(patterns)
}

/// Create a default `.tree_ignore` file with common ignore patterns
fn create_default_ignore_file<P: AsRef<Path>>(base_path: P) -> Result<()> {
    let base_path = base_path.as_ref();
    let ignore_file_path = base_path.join(".tree_ignore");

    let default_content = r"# Tree ignore patterns configuration file
# This file controls which directories and files are ignored when printing the tree
# Add one pattern per line (exact name matches only)
# Lines starting with # are comments and will be ignored
#
# You can edit this file to customize which items are ignored
# Use 'tree --clear' to remove this configuration file

# Build and compilation outputs
target
build
dist
out

# Dependencies and package managers
node_modules
vendor
.pnpm-store

# Version control
.git
.svn
.hg

# IDE and editor files
.vscode
.idea
.idea.old
*.swp
*.swo
*~

# OS generated files
.DS_Store
Thumbs.db

# Temporary and cache directories
tmp
temp
cache
.cache

# Legacy or backup directories
old_do_not_use
backup
";

    fs::write(&ignore_file_path, default_content)
        .with_context(|| format!("Failed to create ignore file: {}", ignore_file_path.display()))?;

    println!("Created default .tree_ignore file at: {}", ignore_file_path.display());
    println!("You can edit this file to customize ignore patterns.");

    Ok(())
}

/// Function to print the directory tree recursively with proper formatting
fn print_directory_tree_recursive_short<W: Write>(
    path: &Path,
    prefix: &str,
    handle: &mut W,
    ignored_paths: &[PathBuf],
) -> Result<()> {
    // Skip if this path is in the ignored list
    if ignored_paths.iter().any(|ignored| ignored == path) {
        return Ok(());
    }

    // Read directory entries
    let mut entries: Vec<_> = fs::read_dir(path)
        .context("Failed to read directory")?
        .filter_map(std::result::Result::ok)
        .filter(|entry| {
            // Filter out ignored paths
            !ignored_paths.iter().any(|ignored| ignored == &entry.path())
        })
        .collect();

    // Sort entries: directories first, then files, both alphabetically
    entries.sort_by(|a, b| {
        let a_is_dir = a.path().is_dir();
        let b_is_dir = b.path().is_dir();
        
        match (a_is_dir, b_is_dir) {
            (true, false) => std::cmp::Ordering::Less,
            (false, true) => std::cmp::Ordering::Greater,
            _ => a.file_name().cmp(&b.file_name()),
        }
    });

    for (i, entry) in entries.iter().enumerate() {
        let is_last = i == entries.len() - 1;
        let entry_path = entry.path();
        let file_name = entry.file_name().to_string_lossy().to_string();

        // Choose the appropriate tree characters
        let (current_prefix, next_prefix) = if is_last {
            ("└── ", "    ")
        } else {
            ("├── ", "│   ")
        };

        // Print the current entry
        writeln!(handle, "{prefix}{current_prefix}{file_name}")
            .context("Failed to write to output")?;

        // If it's a directory, recurse into it
        if entry_path.is_dir() {
            let new_prefix = format!("{prefix}{next_prefix}");
            print_directory_tree_recursive_short(
                &entry_path,
                &new_prefix,
                handle,
                ignored_paths,
            )?;
        }
    }

    Ok(())
}



/// Function to print the directory tree.
pub fn print_directory_tree<P: AsRef<Path>>(path: P) -> Result<()> {
    let path = path.as_ref();
    let stdout = io::stdout();
    let mut handle = stdout.lock();
    writeln!(handle, "{}", path.display()).context("Failed to write to stdout")?;

    // Check if .tree_ignore file exists, create default if not
    let ignore_file_path = path.join(".tree_ignore");
    if !ignore_file_path.exists() {
        create_default_ignore_file(path)?;
    }

    // Read ignore patterns from .tree_ignore file
    let ignore_patterns = read_ignore_patterns(path)?;

    // Collect all entries while respecting ignore rules
    let ignore_walker = WalkBuilder::new(path)
        .git_ignore(true) // Respect .gitignore
        .hidden(false) // Skip hidden files
        .filter_entry(move |entry| !should_ignore(entry, &ignore_patterns)) // Custom filter logic using file patterns
        .build();

    let filtered_entries: HashSet<PathBuf> = ignore_walker
        .filter_map(std::result::Result::ok)
        .map(|entry| entry.path().to_path_buf())
        .collect();

    // Collect all entries without applying filters
    let all_walker = WalkBuilder::new(path)
        .git_ignore(false)
        .hidden(false)
        .build();

    let all_entries: HashSet<PathBuf> = all_walker
        .filter_map(std::result::Result::ok)
        .map(|entry| entry.path().to_path_buf())
        .collect();

    // Find the symmetric difference between the two sets
    let diff: Vec<_> = all_entries
        .symmetric_difference(&filtered_entries)
        .cloned()
        .collect();

    // Print the directory tree recursively
    print_directory_tree_recursive_short(path, "", &mut handle, &diff)?;

    Ok(())
}
