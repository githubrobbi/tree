// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Robert Nio

// Allow unused crate dependencies since not all dev dependencies are used in every test file
#![allow(unused_crate_dependencies)]

//! # Integration Tests for Tree CLI
//!
//! This module contains comprehensive integration tests for the tree CLI application,
//! testing the complete end-to-end functionality including command-line argument
//! parsing, file system operations, and output generation.
//!
//! ## Test Philosophy
//!
//! These tests focus on **black-box testing** of the CLI binary:
//! - **Real filesystem operations** - Tests use actual temporary directories
//! - **Complete command execution** - Tests invoke the actual binary
//! - **Output validation** - Tests verify both stdout and stderr content
//! - **Exit code verification** - Tests ensure proper success/failure signaling
//! - **Cross-platform compatibility** - Tests work on Windows, macOS, and Linux
//!
//! ## Test Categories
//!
//! 1. **Basic functionality** - Core tree printing and clearing operations
//! 2. **Error handling** - Invalid paths, permissions, edge cases
//! 3. **Ignore patterns** - `.gitignore` and `.tree_ignore` integration
//! 4. **Command-line interface** - Argument parsing and help output
//! 5. **File system edge cases** - Empty directories, special characters, etc.
//!
//! ## Testing Tools
//!
//! - **`assert_cmd`** - For CLI testing with process spawning and output capture
//! - **`predicates`** - For flexible output matching and validation
//! - **`tempfile`** - For safe temporary directory creation and cleanup
//! - **Standard assertions** - For precise value and behavior verification
//!
//! ## Test Isolation
//!
//! Each test creates its own temporary directory to ensure complete isolation
//! and prevent test interference. Cleanup is automatic via RAII patterns.

#![allow(clippy::unwrap_used)] // Tests should panic on failure
#![allow(clippy::expect_used)] // Tests should panic on failure

use assert_cmd::Command;
use predicates::prelude::*;
use std::fs;
use tempfile::TempDir;

/// Test that the CLI binary can be executed and shows help
#[test]
fn test_cli_help() {
    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg("--help")
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "Tree is a modern directory tree printer",
        ));
}

/// Test that the CLI binary shows version information
#[test]
fn test_cli_version() {
    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg("--version")
        .assert()
        .success()
        .stdout(predicate::str::contains("tree"));
}

/// Test basic tree printing functionality
#[test]
fn test_cli_basic_tree_printing() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();

    // Create a simple directory structure
    fs::create_dir(base_path.join("src")).unwrap();
    fs::write(base_path.join("src/main.rs"), "fn main() {}").unwrap();
    fs::write(base_path.join("README.md"), "# Test").unwrap();

    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg(base_path.to_str().unwrap())
        .assert()
        .success()
        .stdout(predicate::str::contains("src"))
        .stdout(predicate::str::contains("README.md"));
}

/// Test clear functionality
#[test]
fn test_cli_clear_functionality() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();

    // Create some .tree_ignore files
    fs::write(base_path.join(".tree_ignore"), "target\nnode_modules").unwrap();
    fs::create_dir(base_path.join("subdir")).unwrap();
    fs::write(base_path.join("subdir/.tree_ignore"), "test").unwrap();

    // Verify files exist
    assert!(base_path.join(".tree_ignore").exists());
    assert!(base_path.join("subdir/.tree_ignore").exists());

    // Run clear command
    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg("--clear")
        .arg(base_path.to_str().unwrap())
        .assert()
        .success()
        .stdout(predicate::str::contains("Removed 2 .tree_ignore file(s)"));

    // Verify files are removed
    assert!(!base_path.join(".tree_ignore").exists());
    assert!(!base_path.join("subdir/.tree_ignore").exists());
}

/// Test error handling for non-existent path
#[test]
fn test_cli_nonexistent_path() {
    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg("/nonexistent/path/that/does/not/exist")
        .assert()
        .failure()
        .stderr(predicate::str::contains("does not exist"));
}

/// Test error handling for file instead of directory
#[test]
fn test_cli_file_instead_of_directory() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("test_file.txt");
    fs::write(&file_path, "test content").unwrap();

    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg(file_path.to_str().unwrap())
        .assert()
        .failure()
        .stderr(predicate::str::contains("is not a directory"));
}

/// Test that `.tree_ignore` file is created when it doesn't exist
#[test]
fn test_cli_creates_tree_ignore_file() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();

    // Create a simple directory structure
    fs::create_dir(base_path.join("src")).unwrap();
    fs::write(base_path.join("src/main.rs"), "fn main() {}").unwrap();

    // Verify .tree_ignore doesn't exist initially
    assert!(!base_path.join(".tree_ignore").exists());

    // Run tree command
    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg(base_path.to_str().unwrap()).assert().success();

    // Verify .tree_ignore was created
    assert!(base_path.join(".tree_ignore").exists());

    // Verify it has expected content
    let content = fs::read_to_string(base_path.join(".tree_ignore")).unwrap();
    assert!(content.contains("target"));
    assert!(content.contains("node_modules"));
}

/// Test short form of clear flag
#[test]
fn test_cli_clear_short_flag() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();

    // Create a .tree_ignore file
    fs::write(base_path.join(".tree_ignore"), "test").unwrap();

    // Run clear command with short flag
    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg("-c")
        .arg(base_path.to_str().unwrap())
        .assert()
        .success()
        .stdout(predicate::str::contains("Removed 1 .tree_ignore file(s)"));
}

#[test]
fn test_clear_with_no_ignore_files() {
    let temp_dir = tempfile::tempdir().unwrap();
    let temp_path = temp_dir.path();

    // Create some regular files but no .tree_ignore files
    fs::create_dir_all(temp_path.join("src")).unwrap();
    fs::write(temp_path.join("src/main.rs"), "fn main() {}").unwrap();
    fs::write(temp_path.join("Cargo.toml"), "[package]\nname = \"test\"").unwrap();

    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg("--clear")
        .arg(temp_path)
        .assert()
        .success()
        .stdout(predicate::str::contains("Removed 0 .tree_ignore file(s)"));
}

#[test]
fn test_print_with_no_existing_ignore_file() {
    let temp_dir = tempfile::tempdir().unwrap();
    let temp_path = temp_dir.path();

    // Create a simple directory structure with no .tree_ignore file
    fs::create_dir_all(temp_path.join("src")).unwrap();
    fs::write(temp_path.join("src/lib.rs"), "// library code").unwrap();

    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg(temp_path)
        .assert()
        .success()
        .stdout(predicate::str::contains("src/"))
        .stdout(predicate::str::contains("lib.rs"));

    // Verify .tree_ignore was created
    assert!(temp_path.join(".tree_ignore").exists());
}

/// When the CLI prints a tree, every directory entry must end with `/`.
#[test]
fn directories_are_rendered_with_slash_suffix() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    fs::create_dir(root.join("src")).unwrap();
    fs::write(root.join("src/main.rs"), "fn main() {}").unwrap();

    let mut cmd = Command::cargo_bin("tree").unwrap();
    cmd.arg(root)
        .assert()
        .success()
        .stdout(predicate::str::contains("src/")); // <- slash is important
}

/// Directories must come *before* files and both are alphabetically sorted.
#[test]
fn render_sorting_and_order() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    // Intentionally shuffled creation order
    fs::write(root.join("b_file.txt"), "").unwrap();
    fs::write(root.join("a_file.txt"), "").unwrap();
    fs::create_dir(root.join("z_dir")).unwrap();
    fs::create_dir(root.join("m_dir")).unwrap();

    let output = Command::cargo_bin("tree")
        .unwrap()
        .arg(root)
        .output()
        .unwrap();
    assert!(output.status.success());

    let text = String::from_utf8(output.stdout).unwrap();

    // Positions must follow: directories (m_dir, z_dir) then files (a_file, b_file)
    let m_pos = text.find("m_dir/").unwrap();
    let z_pos = text.find("z_dir/").unwrap();
    let a_pos = text.find("a_file.txt").unwrap();
    let b_pos = text.find("b_file.txt").unwrap();

    assert!(m_pos < z_pos && z_pos < a_pos && a_pos < b_pos);
}
