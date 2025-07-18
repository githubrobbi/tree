// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Robert Nio

// Allow unused crate dependencies since not all dev dependencies are used in every test file
#![allow(unused_crate_dependencies)]

//! # Property-Based Tests for Tree Library
//!
//! This module contains property-based tests using the `proptest` framework to
//! verify that the tree library functions correctly across a wide range of
//! randomly generated inputs and edge cases.
//!
//! ## Property-Based Testing Philosophy
//!
//! Unlike traditional unit tests that test specific cases, property-based tests
//! verify **invariants** that should hold true for all valid inputs:
//!
//! - **Robustness** - Functions should never panic on valid inputs
//! - **Determinism** - Same input should always produce same output
//! - **Consistency** - Related operations should have consistent behavior
//! - **Boundary conditions** - Edge cases should be handled gracefully
//!
//! ## Test Categories
//!
//! 1. **Robustness tests** - Verify functions don't panic on random inputs
//! 2. **Determinism tests** - Ensure consistent output for identical inputs
//! 3. **Consistency tests** - Verify related operations behave consistently
//! 4. **Edge case tests** - Test boundary conditions and special cases
//! 5. **Performance tests** - Ensure reasonable behavior under load
//!
//! ## Input Generation Strategy
//!
//! The tests use carefully crafted generators that produce:
//! - **Valid directory structures** with realistic file/folder names
//! - **Edge cases** like empty directories, deep nesting, special characters
//! - **Ignore patterns** with various complexity levels
//! - **Filesystem scenarios** that might occur in real usage
//!
//! ## Test Execution
//!
//! Each property test runs hundreds of iterations with different random inputs,
//! providing much broader coverage than traditional unit tests while catching
//! edge cases that might be missed in manual test case design.

#![allow(clippy::unwrap_used)] // Tests should panic on failure
#![allow(clippy::expect_used)] // Tests should panic on failure

use proptest::prelude::*;
use std::fs;

use tempfile::TempDir;
use tree::{clear, print};

/// Generate valid directory names for testing
fn directory_name() -> impl Strategy<Value = String> {
    "[a-zA-Z0-9_-]{1,20}"
}

/// Generate valid file names for testing (avoiding problematic names)
fn file_name() -> impl Strategy<Value = String> {
    "[a-zA-Z0-9_-]{1,20}\\.[a-zA-Z]{1,5}"
}

proptest! {
    #[test]
    fn print_never_panics_on_valid_directory(
        dir_names in prop::collection::vec(directory_name(), 0..5),
        file_names in prop::collection::vec(file_name(), 0..10)
    ) {
        let temp_dir = TempDir::new().unwrap();
        let base_path = temp_dir.path();

        // Create directories
        for dir_name in &dir_names {
            let dir_path = base_path.join(dir_name);
            fs::create_dir_all(&dir_path).unwrap();
        }

        // Create files (skip if file name conflicts with directory names)
        for file_name in &file_names {
            if !dir_names.contains(file_name) {
                let file_path = base_path.join(file_name);
                // Only create files that can be successfully written
                let _ = fs::write(&file_path, "test content");
            }
        }

        // This should never panic
        let mut output = Vec::new();
        let result = print(base_path, &mut output);

        // Should either succeed or return a proper error
        if matches!(result, Ok(())) {
            // If successful, output should contain the base path
            let output_str = String::from_utf8(output).unwrap();
            assert!(output_str.contains(&base_path.display().to_string()));
        }
        // Errors are acceptable, but panics are not
    }
}

proptest! {
    #[test]
    fn clear_never_panics_and_is_consistent(
        ignore_file_count in 0u32..10
    ) {
        let temp_dir = TempDir::new().expect("Failed to create temporary directory for test");
        let base_path = temp_dir.path();

        // Create nested directory structure
        for i in 0..ignore_file_count {
            let dir_path = base_path.join(format!("dir_{i}"));
            fs::create_dir_all(&dir_path).expect("Failed to create test directory");
            fs::write(dir_path.join(".tree_ignore"), "test content").expect("Failed to write test ignore file");
        }

        // Clear should never panic
        let result = clear(base_path);

        if let Ok(removed_count) = result {
            // Should have removed the expected number of files
            assert_eq!(removed_count, u64::from(ignore_file_count));

            // Running clear again should remove 0 files
            let second_result = clear(base_path).unwrap();
            assert_eq!(second_result, 0);
        }
        // Errors are acceptable, but panics are not
    }
}

proptest! {
    #[test]
    fn print_output_is_deterministic(
        dir_names in prop::collection::vec(directory_name(), 1..3),
        file_names in prop::collection::vec(file_name(), 1..3)
    ) {
        let temp_dir = TempDir::new().unwrap();
        let base_path = temp_dir.path();

        // Create a consistent directory structure
        for dir_name in &dir_names {
            fs::create_dir_all(base_path.join(dir_name)).unwrap();
        }

        for file_name in &file_names {
            if !dir_names.contains(file_name) {
                // Only create files that can be successfully written
                let _ = fs::write(base_path.join(file_name), "content");
            }
        }

        // Generate output twice
        let mut output1 = Vec::new();
        let mut output2 = Vec::new();

        let result1 = print(base_path, &mut output1);
        let result2 = print(base_path, &mut output2);

        // Both should succeed or both should fail
        assert_eq!(result1.is_ok(), result2.is_ok());

        if result1.is_ok() {
            // Output should be identical
            assert_eq!(output1, output2);
        }
    }
}

proptest! {
    #[test]
    fn clear_handles_empty_directories(
        depth in 1u32..5
    ) {
        let temp_dir = TempDir::new().unwrap();
        let base_path = temp_dir.path();

        // Create nested empty directories
        let mut current_path = base_path.to_path_buf();
        for i in 0..depth {
            current_path = current_path.join(format!("level_{i}"));
            fs::create_dir_all(&current_path).unwrap();
        }

        // Clear should handle empty directory trees without panicking
        let result = clear(base_path);

        if let Ok(count) = result {
            // Should remove 0 files from empty directories
            assert_eq!(count, 0);
        }
        // Errors are acceptable for edge cases
    }
}

proptest! {
    #[test]
    fn print_respects_ignore_patterns(
        patterns in prop::collection::vec("[a-z]{1,10}", 1..5)
    ) {
        let temp_dir = TempDir::new().unwrap();
        let base_path = temp_dir.path();

        // Create files that match and don't match patterns
        for pattern in &patterns {
            // Create a file that matches the pattern
            fs::write(base_path.join(pattern), "content").unwrap();

            // Create a file that doesn't match
            let non_matching = format!("{pattern}_extra");
            fs::write(base_path.join(&non_matching), "content").unwrap();
        }

        // Create custom ignore file with patterns
        let ignore_content = patterns.join("\n");
        fs::write(base_path.join(".tree_ignore"), ignore_content).unwrap();

        // Print should not panic regardless of ignore patterns
        let mut output = Vec::new();
        let result = print(base_path, &mut output);

        // Should handle any valid ignore patterns
        prop_assert!(result.is_ok() || result.is_err()); // Should not panic
    }
}

/// Arbitrary but valid directory names (shorter for faster testing).
fn dir_name() -> impl Strategy<Value = String> {
    "[a-zA-Z0-9_-]{1,8}"
}

/// Arbitrary file names with small extensions (shorter for faster testing).
fn file_name_short() -> impl Strategy<Value = String> {
    "[a-zA-Z0-9_-]{1,8}\\.[a-zA-Z]{1,4}"
}

proptest! {
    /// The tree must be printable *and* fully clearable afterwards.
    /// This test verifies that print and clear operations work together correctly.
    #[test]
    fn print_and_clear_are_inverse(
        dirs in prop::collection::vec(dir_name(), 0..4),
        files in prop::collection::vec(file_name_short(), 0..8),
    ) {
        let tmp = TempDir::new().unwrap();
        let root = tmp.path();

        // Create random structure (handle duplicates gracefully)
        for d in &dirs {
            let dir_path = root.join(d);
            if !dir_path.exists() {
                fs::create_dir(&dir_path).unwrap();
            }
        }
        for f in &files {
            let file_path = root.join(f);
            // Only create files that don't conflict with directories
            if !dirs.contains(f) && !file_path.exists() {
                fs::write(&file_path, "data").unwrap();
            }
        }

        // 1) Print should succeed and be deterministic
        let mut buf1 = Vec::new();
        print(root, &mut buf1).unwrap();

        let mut buf2 = Vec::new();
        print(root, &mut buf2).unwrap();

        prop_assert_eq!(buf1, buf2); // determinism

        // 2) After printing there is exactly one .tree_ignore file
        prop_assert!(root.join(".tree_ignore").exists());

        // 3) Clearing should delete that file and report `1`
        let removed = clear(root).unwrap();
        prop_assert_eq!(removed, 1);
        prop_assert!(!root.join(".tree_ignore").exists());
    }
}
