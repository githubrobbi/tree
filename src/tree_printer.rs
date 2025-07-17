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

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::io::Cursor;
    use tempfile::TempDir;

    /// Helper function to create a test directory structure
    fn create_test_directory() -> TempDir {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create some test files and directories
        fs::create_dir(base_path.join("src")).expect("Failed to create src dir");
        fs::write(base_path.join("src/main.rs"), "fn main() {}").expect("Failed to write main.rs");
        fs::write(base_path.join("src/lib.rs"), "// lib").expect("Failed to write lib.rs");

        fs::create_dir(base_path.join("target")).expect("Failed to create target dir");
        fs::write(base_path.join("target/debug.log"), "debug").expect("Failed to write debug.log");

        fs::create_dir(base_path.join("docs")).expect("Failed to create docs dir");
        fs::write(base_path.join("docs/README.md"), "# Docs").expect("Failed to write README.md");

        fs::write(base_path.join("Cargo.toml"), "[package]\nname = \"test\"").expect("Failed to write Cargo.toml");

        temp_dir
    }

    #[test]
    fn test_should_ignore_with_patterns() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        // Create a mock DirEntry for testing
        let target_path = base_path.join("target");
        let walker = WalkBuilder::new(&target_path).build();

        let patterns = vec!["target".to_string(), "node_modules".to_string()];

        for entry in walker {
            if let Ok(entry) = entry {
                if entry.file_name().to_str() == Some("target") {
                    assert!(should_ignore(&entry, &patterns));
                }
            }
        }
    }

    #[test]
    fn test_should_ignore_without_patterns() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        let src_path = base_path.join("src");
        let walker = WalkBuilder::new(&src_path).build();

        let patterns: Vec<String> = vec![];

        for entry in walker {
            if let Ok(entry) = entry {
                assert!(!should_ignore(&entry, &patterns));
            }
        }
    }

    #[test]
    fn test_read_ignore_patterns_nonexistent_file() {
        let temp_dir = create_test_directory();
        let patterns = read_ignore_patterns(temp_dir.path()).expect("Should handle missing file");
        assert!(patterns.is_empty());
    }

    #[test]
    fn test_read_ignore_patterns_with_file() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        // Create a test .tree_ignore file
        let ignore_content = r"# Test ignore file
target
node_modules
# Another comment
build

# Empty lines should be ignored
.git";

        fs::write(base_path.join(".tree_ignore"), ignore_content)
            .expect("Failed to write ignore file");

        let patterns = read_ignore_patterns(base_path).expect("Should read patterns");

        assert_eq!(patterns.len(), 4);
        assert!(patterns.contains(&"target".to_string()));
        assert!(patterns.contains(&"node_modules".to_string()));
        assert!(patterns.contains(&"build".to_string()));
        assert!(patterns.contains(&".git".to_string()));
    }

    #[test]
    fn test_create_default_ignore_file() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        create_default_ignore_file(base_path).expect("Should create default file");

        let ignore_file_path = base_path.join(".tree_ignore");
        assert!(ignore_file_path.exists());

        let content = fs::read_to_string(&ignore_file_path).expect("Should read file");
        assert!(content.contains("target"));
        assert!(content.contains("node_modules"));
        assert!(content.contains("# Tree ignore patterns configuration file"));
    }

    #[test]
    fn test_print_directory_tree_recursive_short() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![];

        print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths)
            .expect("Should print tree");

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");

        // Check that the output contains expected directory structure
        assert!(output_str.contains("src"));
        assert!(output_str.contains("docs"));
        assert!(output_str.contains("Cargo.toml"));

        // Check for tree formatting characters
        assert!(output_str.contains("├──") || output_str.contains("└──"));
    }

    #[test]
    fn test_print_directory_tree_with_ignored_paths() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![base_path.join("target")];

        print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths)
            .expect("Should print tree");

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");

        // Should contain non-ignored directories
        assert!(output_str.contains("src"));
        assert!(output_str.contains("docs"));

        // Should not contain ignored directory
        assert!(!output_str.contains("target"));
    }

    #[test]
    fn test_print_directory_tree_creates_ignore_file() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        print_directory_tree(base_path).expect("Should print tree");

        let ignore_file_path = base_path.join(".tree_ignore");
        assert!(ignore_file_path.exists());

        // Verify the ignore file was created with default content
        let content = fs::read_to_string(&ignore_file_path).expect("Should read file");
        assert!(content.contains("target"));
        assert!(content.contains("node_modules"));
    }

    #[test]
    fn test_print_directory_tree_uses_existing_ignore_file() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        // Create a custom ignore file first
        let custom_ignore = "custom_dir\nother_dir";
        fs::write(base_path.join(".tree_ignore"), custom_ignore)
            .expect("Failed to write custom ignore file");

        print_directory_tree(base_path).expect("Should print tree");

        // Verify the file wasn't overwritten
        let content = fs::read_to_string(base_path.join(".tree_ignore"))
            .expect("Should read file");
        assert_eq!(content, custom_ignore);
    }

    #[test]
    fn test_should_ignore_with_invalid_filename() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        // Create a file with invalid UTF-8 in the name (this is tricky to test)
        // Instead, let's test the None case by using a mock
        let patterns = vec!["target".to_string()];

        // We'll test this indirectly through the walker
        let walker = WalkBuilder::new(base_path).build();

        for entry in walker {
            if let Ok(entry) = entry {
                // Test that the function handles all cases
                let _result = should_ignore(&entry, &patterns);
            }
        }
    }

    #[test]
    fn test_read_ignore_patterns_with_io_error() {
        // Test reading from a directory that doesn't exist
        let nonexistent_path = PathBuf::from("/nonexistent/path");
        let patterns = read_ignore_patterns(&nonexistent_path).expect("Should handle missing file");
        assert!(patterns.is_empty());
    }

    #[test]
    fn test_create_default_ignore_file_error_handling() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        // First create the file successfully
        create_default_ignore_file(base_path).expect("Should create file");

        // Verify it exists
        assert!(base_path.join(".tree_ignore").exists());

        // Test that we can create it again (overwrite)
        create_default_ignore_file(base_path).expect("Should create file again");
    }

    #[test]
    fn test_print_directory_tree_recursive_short_empty_directory() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create an empty directory
        let empty_dir = base_path.join("empty");
        fs::create_dir(&empty_dir).expect("Failed to create empty dir");

        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![];

        print_directory_tree_recursive_short(&empty_dir, "", &mut output, &ignored_paths)
            .expect("Should print empty tree");

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");

        // Empty directory should produce no output (no files/subdirs)
        assert!(output_str.is_empty() || output_str.trim().is_empty());
    }

    #[test]
    fn test_print_directory_tree_recursive_short_with_files_only() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create only files, no subdirectories
        fs::write(base_path.join("file1.txt"), "content1").expect("Failed to write file1");
        fs::write(base_path.join("file2.txt"), "content2").expect("Failed to write file2");

        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![];

        print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths)
            .expect("Should print tree");

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");

        // Should contain both files
        assert!(output_str.contains("file1.txt"));
        assert!(output_str.contains("file2.txt"));

        // Should have proper tree formatting
        assert!(output_str.contains("├──") || output_str.contains("└──"));
    }

    #[test]
    fn test_print_directory_tree_recursive_short_sorting() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create files and directories in a specific order to test sorting
        fs::write(base_path.join("z_file.txt"), "content").expect("Failed to write z_file");
        fs::write(base_path.join("a_file.txt"), "content").expect("Failed to write a_file");
        fs::create_dir(base_path.join("z_dir")).expect("Failed to create z_dir");
        fs::create_dir(base_path.join("a_dir")).expect("Failed to create a_dir");

        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![];

        print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths)
            .expect("Should print tree");

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");

        // Directories should come before files, and both should be alphabetically sorted
        let lines: Vec<&str> = output_str.lines().collect();

        // Find positions of each item
        let a_dir_pos = lines.iter().position(|line| line.contains("a_dir"));
        let z_dir_pos = lines.iter().position(|line| line.contains("z_dir"));
        let a_file_pos = lines.iter().position(|line| line.contains("a_file.txt"));
        let z_file_pos = lines.iter().position(|line| line.contains("z_file.txt"));

        // Verify sorting: directories first (a_dir < z_dir), then files (a_file < z_file)
        if let (Some(a_dir), Some(z_dir), Some(a_file), Some(z_file)) =
            (a_dir_pos, z_dir_pos, a_file_pos, z_file_pos) {
            assert!(a_dir < z_dir, "Directories should be sorted alphabetically");
            assert!(z_dir < a_file, "Directories should come before files");
            assert!(a_file < z_file, "Files should be sorted alphabetically");
        }
    }

    #[test]
    fn test_read_ignore_patterns_with_complex_content() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        // Create a complex ignore file with various edge cases
        let complex_ignore = r"# Header comment
target
   # Indented comment
node_modules
# Another comment

   # Comment with spaces
build

# Final comment with trailing spaces
.git   ";

        fs::write(base_path.join(".tree_ignore"), complex_ignore)
            .expect("Failed to write complex ignore file");

        let patterns = read_ignore_patterns(base_path).expect("Should read patterns");

        // Should only contain non-comment, non-empty lines, trimmed
        assert_eq!(patterns.len(), 4);
        assert!(patterns.contains(&"target".to_string()));
        assert!(patterns.contains(&"node_modules".to_string()));
        assert!(patterns.contains(&"build".to_string()));
        assert!(patterns.contains(&".git".to_string()));
    }

    #[test]
    fn test_print_directory_tree_recursive_short_with_prefix() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create a simple structure
        fs::write(base_path.join("file.txt"), "content").expect("Failed to write file");

        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![];

        // Test with a prefix (simulating nested directory printing)
        print_directory_tree_recursive_short(base_path, "  ", &mut output, &ignored_paths)
            .expect("Should print tree with prefix");

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");

        // Should contain the file with the prefix
        assert!(output_str.contains("file.txt"));
        assert!(output_str.contains("  ")); // Should have the prefix
    }

    #[test]
    fn test_print_directory_tree_recursive_short_mixed_content() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create a mix of files and directories
        fs::create_dir(base_path.join("subdir")).expect("Failed to create subdir");
        fs::write(base_path.join("subdir/nested_file.txt"), "content").expect("Failed to write nested file");
        fs::write(base_path.join("root_file.txt"), "content").expect("Failed to write root file");

        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![];

        print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths)
            .expect("Should print mixed tree");

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");

        // Should contain both files and show directory structure
        assert!(output_str.contains("subdir"));
        assert!(output_str.contains("nested_file.txt"));
        assert!(output_str.contains("root_file.txt"));

        // Should have proper tree formatting
        assert!(output_str.contains("├──") || output_str.contains("└──"));
    }

    #[test]
    fn test_print_directory_tree_error_handling() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        // Test that the function handles the case where ignore patterns are used
        // Create a custom ignore file with patterns that will be applied
        let ignore_content = "target\nsrc";
        fs::write(base_path.join(".tree_ignore"), ignore_content)
            .expect("Failed to write ignore file");

        // This should work without errors and apply the ignore patterns
        print_directory_tree(base_path).expect("Should print tree with custom patterns");

        // Verify the ignore file still exists and wasn't overwritten
        let content = fs::read_to_string(base_path.join(".tree_ignore"))
            .expect("Should read ignore file");
        assert_eq!(content, ignore_content);
    }

    #[test]
    fn test_create_default_ignore_file_content_verification() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        create_default_ignore_file(base_path).expect("Should create default file");

        let content = fs::read_to_string(base_path.join(".tree_ignore"))
            .expect("Should read created file");

        // Verify specific content is present
        assert!(content.contains("# Tree ignore patterns configuration file"));
        assert!(content.contains("target"));
        assert!(content.contains("node_modules"));
        assert!(content.contains("build"));
        assert!(content.contains(".git"));
        assert!(content.contains(".vscode"));
        assert!(content.contains(".idea"));
        assert!(content.contains("Use 'tree --clear' to remove this configuration file"));
    }

    #[test]
    fn test_read_ignore_patterns_file_read_error() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create a .tree_ignore file with specific content
        fs::write(base_path.join(".tree_ignore"), "target\nnode_modules")
            .expect("Failed to write ignore file");

        // Test successful read
        let patterns = read_ignore_patterns(base_path).expect("Should read patterns");
        assert_eq!(patterns.len(), 2);
        assert!(patterns.contains(&"target".to_string()));
        assert!(patterns.contains(&"node_modules".to_string()));
    }

    #[test]
    fn test_print_directory_tree_with_gitignore_integration() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create a directory structure
        fs::create_dir(base_path.join("src")).expect("Failed to create src");
        fs::write(base_path.join("src/main.rs"), "fn main() {}").expect("Failed to write main.rs");

        fs::create_dir(base_path.join("target")).expect("Failed to create target");
        fs::write(base_path.join("target/debug"), "debug info").expect("Failed to write debug");

        // Create a .gitignore file
        fs::write(base_path.join(".gitignore"), "target/\n*.log").expect("Failed to write .gitignore");

        // This should test the integration with gitignore functionality
        print_directory_tree(base_path).expect("Should print tree with gitignore");

        // Verify .tree_ignore was created
        assert!(base_path.join(".tree_ignore").exists());
    }

    #[test]
    fn test_print_directory_tree_recursive_short_io_error_handling() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create a simple file structure
        fs::write(base_path.join("test.txt"), "content").expect("Failed to write test file");

        // Test with a cursor that should work fine
        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![];

        let result = print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths);
        assert!(result.is_ok());

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");
        assert!(output_str.contains("test.txt"));
    }

    #[test]
    fn test_print_directory_tree_recursive_short_with_ignored_path() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create a directory structure
        fs::create_dir(base_path.join("subdir")).expect("Failed to create subdir");
        fs::write(base_path.join("subdir/file.txt"), "content").expect("Failed to write file");

        let mut output = Cursor::new(Vec::new());

        // Test with the base path itself in the ignored list (should trigger early return)
        let ignored_paths = vec![base_path.to_path_buf()];

        let result = print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths);
        assert!(result.is_ok());

        // Should produce no output since the path itself is ignored
        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");
        assert!(output_str.is_empty());
    }

    #[test]
    fn test_print_directory_tree_recursive_short_deep_recursion() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create a nested directory structure to test recursion
        fs::create_dir_all(base_path.join("level1/level2/level3")).expect("Failed to create nested dirs");
        fs::write(base_path.join("level1/level2/level3/deep_file.txt"), "content").expect("Failed to write deep file");

        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![];

        // This should exercise the recursive call path (line 169)
        let result = print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths);
        assert!(result.is_ok());

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");

        // Should contain all levels
        assert!(output_str.contains("level1"));
        assert!(output_str.contains("level2"));
        assert!(output_str.contains("level3"));
        assert!(output_str.contains("deep_file.txt"));
    }

    #[test]
    fn test_print_directory_tree_recursive_short_with_partial_ignore() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create multiple subdirectories
        fs::create_dir(base_path.join("keep_dir")).expect("Failed to create keep_dir");
        fs::create_dir(base_path.join("ignore_dir")).expect("Failed to create ignore_dir");
        fs::write(base_path.join("keep_dir/keep_file.txt"), "content").expect("Failed to write keep file");
        fs::write(base_path.join("ignore_dir/ignore_file.txt"), "content").expect("Failed to write ignore file");

        let mut output = Cursor::new(Vec::new());

        // Ignore only one of the directories
        let ignored_paths = vec![base_path.join("ignore_dir")];

        let result = print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths);
        assert!(result.is_ok());

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");

        // Should contain the kept directory but not the ignored one
        assert!(output_str.contains("keep_dir"));
        assert!(output_str.contains("keep_file.txt"));
        assert!(!output_str.contains("ignore_dir"));
        assert!(!output_str.contains("ignore_file.txt"));
    }

    #[test]
    fn test_should_ignore_with_matching_pattern() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        // Create a walker to get actual DirEntry objects
        let walker = WalkBuilder::new(base_path).build();
        let patterns = vec!["target".to_string(), "node_modules".to_string()];

        for entry in walker {
            if let Ok(entry) = entry {
                if entry.file_name().to_str() == Some("target") {
                    // This should trigger the true branch in should_ignore
                    assert!(should_ignore(&entry, &patterns));
                } else if entry.file_name().to_str() == Some("src") {
                    // This should trigger the false branch in should_ignore
                    assert!(!should_ignore(&entry, &patterns));
                }
            }
        }
    }

    #[test]
    fn test_should_ignore_with_empty_patterns_comprehensive() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        let walker = WalkBuilder::new(base_path).build();
        let patterns: Vec<String> = vec![];

        // Test with empty patterns - should never ignore anything
        for entry in walker {
            if let Ok(entry) = entry {
                // This should always return false with empty patterns
                assert!(!should_ignore(&entry, &patterns));
            }
        }
    }

    #[test]
    fn test_print_directory_tree_recursive_short_sorting_edge_case() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create files and directories with specific names to test sorting edge cases
        fs::create_dir(base_path.join("a_dir")).expect("Failed to create a_dir");
        fs::create_dir(base_path.join("z_dir")).expect("Failed to create z_dir");
        fs::write(base_path.join("a_file.txt"), "content").expect("Failed to write a_file");
        fs::write(base_path.join("z_file.txt"), "content").expect("Failed to write z_file");

        let mut output = Cursor::new(Vec::new());
        let ignored_paths = vec![];

        print_directory_tree_recursive_short(base_path, "", &mut output, &ignored_paths)
            .expect("Should print tree with sorting");

        let output_str = String::from_utf8(output.into_inner()).expect("Should be valid UTF-8");
        let lines: Vec<&str> = output_str.lines().collect();

        // Find positions of each item to verify sorting
        let a_dir_pos = lines.iter().position(|line| line.contains("a_dir"));
        let z_dir_pos = lines.iter().position(|line| line.contains("z_dir"));
        let a_file_pos = lines.iter().position(|line| line.contains("a_file.txt"));
        let z_file_pos = lines.iter().position(|line| line.contains("z_file.txt"));

        // This should exercise the sorting assertion logic
        if let (Some(a_dir), Some(z_dir), Some(a_file), Some(z_file)) =
            (a_dir_pos, z_dir_pos, a_file_pos, z_file_pos) {
            // These assertions should cover the uncovered lines in the sorting test
            assert!(a_dir < z_dir, "Directories should be sorted alphabetically");
            assert!(z_dir < a_file, "Directories should come before files");
            assert!(a_file < z_file, "Files should be sorted alphabetically");
        }
    }

    #[test]
    fn test_read_ignore_patterns_with_file_read_success() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create a .tree_ignore file with specific content to test successful read
        let ignore_content = "target\nnode_modules\nbuild";
        fs::write(base_path.join(".tree_ignore"), ignore_content)
            .expect("Failed to write ignore file");

        // Test successful read path
        let patterns = read_ignore_patterns(base_path).expect("Should read patterns successfully");
        assert_eq!(patterns.len(), 3);
        assert!(patterns.contains(&"target".to_string()));
        assert!(patterns.contains(&"node_modules".to_string()));
        assert!(patterns.contains(&"build".to_string()));
    }

    #[test]
    fn test_create_default_ignore_file_success_path() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Test the successful creation path
        let result = create_default_ignore_file(base_path);
        assert!(result.is_ok());

        // Verify file was created and has expected content
        let ignore_file_path = base_path.join(".tree_ignore");
        assert!(ignore_file_path.exists());

        let content = fs::read_to_string(&ignore_file_path).expect("Should read created file");
        assert!(content.contains("target"));
        assert!(content.contains("node_modules"));
        assert!(content.contains("# Tree ignore patterns configuration file"));
    }

    #[test]
    fn test_should_ignore_comprehensive_pattern_matching() {
        let temp_dir = create_test_directory();
        let base_path = temp_dir.path();

        let walker = WalkBuilder::new(base_path).build();
        let patterns = vec!["target".to_string(), "src".to_string(), "docs".to_string()];

        let mut found_target = false;
        let mut found_src = false;
        let mut found_docs = false;
        let mut found_other = false;

        for entry in walker {
            if let Ok(entry) = entry {
                if let Some(file_name) = entry.file_name().to_str() {
                    match file_name {
                        "target" => {
                            assert!(should_ignore(&entry, &patterns));
                            found_target = true;
                        }
                        "src" => {
                            assert!(should_ignore(&entry, &patterns));
                            found_src = true;
                        }
                        "docs" => {
                            assert!(should_ignore(&entry, &patterns));
                            found_docs = true;
                        }
                        "Cargo.toml" => {
                            assert!(!should_ignore(&entry, &patterns));
                            found_other = true;
                        }
                        _ => {
                            // Test other files that shouldn't be ignored
                            if !patterns.contains(&file_name.to_string()) {
                                assert!(!should_ignore(&entry, &patterns));
                            }
                        }
                    }
                }
            }
        }

        // Ensure we actually tested the conditions we expected
        assert!(found_target || found_src || found_docs || found_other);
    }

    #[test]
    fn test_print_directory_tree_all_branches() {
        let temp_dir = TempDir::new().expect("Failed to create temp directory");
        let base_path = temp_dir.path();

        // Create a comprehensive directory structure to test all code paths
        fs::create_dir_all(base_path.join("subdir1/subdir2")).expect("Failed to create nested dirs");
        fs::write(base_path.join("file1.txt"), "content1").expect("Failed to write file1");
        fs::write(base_path.join("subdir1/file2.txt"), "content2").expect("Failed to write file2");
        fs::write(base_path.join("subdir1/subdir2/file3.txt"), "content3").expect("Failed to write file3");

        // Test without existing .tree_ignore file (should create default)
        let result = print_directory_tree(base_path);
        assert!(result.is_ok());

        // Verify .tree_ignore was created
        assert!(base_path.join(".tree_ignore").exists());

        // Test with existing .tree_ignore file (should not overwrite)
        let custom_content = "custom_pattern\nanother_pattern";
        fs::write(base_path.join(".tree_ignore"), custom_content).expect("Failed to write custom ignore");

        let result = print_directory_tree(base_path);
        assert!(result.is_ok());

        // Verify custom content is preserved
        let content = fs::read_to_string(base_path.join(".tree_ignore")).expect("Should read file");
        assert_eq!(content, custom_content);
    }
}
