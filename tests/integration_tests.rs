// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Robert Nio

//! Integration tests for the tree CLI tool

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
        .stdout(predicate::str::contains("A simple CLI tool to print directory trees"));
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

/// Test that .tree_ignore file is created when it doesn't exist
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
    cmd.arg(base_path.to_str().unwrap())
        .assert()
        .success();
    
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
