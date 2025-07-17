// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Robert Nio

//! # Edge Case and Error Condition Tests
//!
//! This module contains tests specifically designed to cover edge cases,
//! error conditions, and boundary scenarios that might not be covered
//! by regular integration tests.
//!
//! ## Focus Areas
//!
//! - **Error handling paths** - Testing what happens when operations fail
//! - **Edge cases** - Empty directories, missing files, permission issues
//! - **Boundary conditions** - Unusual but valid inputs
//! - **Recovery scenarios** - How the system handles partial failures
//!
//! These tests are designed to achieve maximum code coverage by exercising
//! code paths that are difficult to trigger in normal usage scenarios.

#![allow(clippy::unwrap_used)]

use std::fs;
use tempfile::TempDir;
use tree::{clear, print};

/// Test clearing when no .tree_ignore files exist (covers early return path)
#[test]
fn test_clear_no_ignore_files_exist() {
    let temp_dir = TempDir::new().unwrap();
    let temp_path = temp_dir.path();

    // Create directory structure with no .tree_ignore files
    fs::create_dir_all(temp_path.join("src")).unwrap();
    fs::create_dir_all(temp_path.join("tests")).unwrap();
    fs::write(temp_path.join("src/lib.rs"), "// code").unwrap();
    fs::write(temp_path.join("tests/test.rs"), "// test").unwrap();

    // This should return 0 and exercise the "no ignore files" path
    let result = clear(temp_path).unwrap();
    assert_eq!(result, 0);
}

/// Test print function when no .tree_ignore file exists initially
#[test]
fn test_print_creates_ignore_file_when_missing() {
    let temp_dir = TempDir::new().unwrap();
    let temp_path = temp_dir.path();

    // Create directory structure without .tree_ignore
    fs::create_dir_all(temp_path.join("src")).unwrap();
    fs::write(temp_path.join("src/main.rs"), "fn main() {}").unwrap();

    // Verify no .tree_ignore exists initially
    assert!(!temp_path.join(".tree_ignore").exists());

    // Print should create the ignore file
    let mut output = Vec::new();
    print(temp_path, &mut output).unwrap();

    // Verify .tree_ignore was created
    assert!(temp_path.join(".tree_ignore").exists());
    
    // Verify output contains expected content
    let output_str = String::from_utf8(output).unwrap();
    assert!(output_str.contains("src/"));
    assert!(output_str.contains("main.rs"));
}

/// Test reading ignore patterns when file doesn't exist (covers early return)
#[test]
fn test_read_ignore_patterns_file_missing() {
    let temp_dir = TempDir::new().unwrap();
    let temp_path = temp_dir.path();

    // Create directory without .tree_ignore file
    fs::create_dir_all(temp_path.join("subdir")).unwrap();

    // This should exercise the early return path in read_ignore_patterns
    let mut output = Vec::new();
    print(temp_path, &mut output).unwrap();

    // Should succeed and create default ignore file
    assert!(temp_path.join(".tree_ignore").exists());
}

/// Test with deeply nested directory structure
#[test]
fn test_deep_directory_structure() {
    let temp_dir = TempDir::new().unwrap();
    let temp_path = temp_dir.path();

    // Create deeply nested structure
    let deep_path = temp_path
        .join("level1")
        .join("level2")
        .join("level3")
        .join("level4");
    fs::create_dir_all(&deep_path).unwrap();
    fs::write(deep_path.join("deep_file.txt"), "deep content").unwrap();

    // Create .tree_ignore files at different levels
    fs::write(temp_path.join(".tree_ignore"), "*.tmp\n").unwrap();
    fs::write(temp_path.join("level1/.tree_ignore"), "level2\n").unwrap();

    let mut output = Vec::new();
    print(temp_path, &mut output).unwrap();

    let output_str = String::from_utf8(output).unwrap();
    assert!(output_str.contains("level1/"));
    
    // Clear should find and remove multiple ignore files
    let removed = clear(temp_path).unwrap();
    assert!(removed >= 1); // At least the root .tree_ignore
}

/// Test with special characters in filenames
#[test]
fn test_special_characters_in_filenames() {
    let temp_dir = TempDir::new().unwrap();
    let temp_path = temp_dir.path();

    // Create files with various special characters (that are valid on most filesystems)
    fs::create_dir_all(temp_path.join("src")).unwrap();
    fs::write(temp_path.join("src/file-with-dashes.rs"), "// code").unwrap();
    fs::write(temp_path.join("src/file_with_underscores.rs"), "// code").unwrap();
    fs::write(temp_path.join("src/file.with.dots.rs"), "// code").unwrap();

    let mut output = Vec::new();
    print(temp_path, &mut output).unwrap();

    let output_str = String::from_utf8(output).unwrap();
    assert!(output_str.contains("file-with-dashes.rs"));
    assert!(output_str.contains("file_with_underscores.rs"));
    assert!(output_str.contains("file.with.dots.rs"));
}

/// Test empty directory handling
#[test]
fn test_empty_directories() {
    let temp_dir = TempDir::new().unwrap();
    let temp_path = temp_dir.path();

    // Create empty directories
    fs::create_dir_all(temp_path.join("empty1")).unwrap();
    fs::create_dir_all(temp_path.join("empty2")).unwrap();
    fs::create_dir_all(temp_path.join("not_empty")).unwrap();
    fs::write(temp_path.join("not_empty/file.txt"), "content").unwrap();

    let mut output = Vec::new();
    print(temp_path, &mut output).unwrap();

    let output_str = String::from_utf8(output).unwrap();
    assert!(output_str.contains("empty1/"));
    assert!(output_str.contains("empty2/"));
    assert!(output_str.contains("not_empty/"));
    assert!(output_str.contains("file.txt"));
}

/// Test ignore patterns with various formats
#[test]
fn test_ignore_file_parsing() {
    let temp_dir = TempDir::new().unwrap();
    let temp_path = temp_dir.path();

    // Create test files
    fs::create_dir_all(temp_path.join("src")).unwrap();
    fs::write(temp_path.join("src/main.rs"), "// main").unwrap();
    fs::write(temp_path.join("src/lib.rs"), "// lib").unwrap();
    fs::write(temp_path.join("README.md"), "# readme").unwrap();

    // First run to create the default .tree_ignore
    let mut output = Vec::new();
    print(temp_path, &mut output).unwrap();

    // Verify .tree_ignore was created and contains expected patterns
    let ignore_path = temp_path.join(".tree_ignore");
    assert!(ignore_path.exists());

    let ignore_content = fs::read_to_string(&ignore_path).unwrap();
    assert!(ignore_content.contains("target"));
    assert!(ignore_content.contains("*.swp"));
    assert!(ignore_content.contains("# Tree ignore patterns"));

    // Verify output contains expected files
    let output_str = String::from_utf8(output).unwrap();
    assert!(output_str.contains("src/"));
    assert!(output_str.contains("main.rs"));
    assert!(output_str.contains("lib.rs"));
    assert!(output_str.contains("README.md"));
}
