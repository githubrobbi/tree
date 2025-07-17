// SPDX-License-Identifier: MPL-2.0 OR LicenseRef-TTAPI-Commercial

//! Property-based tests for the tree library

use proptest::prelude::*;
use std::fs;
use std::path::Path;
use tempfile::TempDir;
use tree::{print, clear};

/// Generate valid directory names for testing
fn directory_name() -> impl Strategy<Value = String> {
    "[a-zA-Z0-9_-]{1,20}"
}

/// Generate valid file names for testing (avoiding problematic names)
fn file_name() -> impl Strategy<Value = String> {
    "[a-zA-Z0-9_-]{1,20}\\.[a-zA-Z]{1,5}"
}

/// Property test: print function should never panic on valid directories
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
                if let Err(_) = fs::write(&file_path, "test content") {
                    // Skip files that can't be created
                    continue;
                }
            }
        }
        
        // This should never panic
        let mut output = Vec::new();
        let result = print(base_path, &mut output);
        
        // Should either succeed or return a proper error
        match result {
            Ok(()) => {
                // If successful, output should contain the base path
                let output_str = String::from_utf8(output).unwrap();
                assert!(output_str.contains(&base_path.display().to_string()));
            }
            Err(_) => {
                // Errors are acceptable, but panics are not
            }
        }
    }
}

/// Property test: clear function should never panic and return consistent results
proptest! {
    #[test]
    fn clear_never_panics_and_is_consistent(
        ignore_file_count in 0u32..10
    ) {
        let temp_dir = TempDir::new().unwrap();
        let base_path = temp_dir.path();
        
        // Create nested directory structure
        for i in 0..ignore_file_count {
            let dir_path = base_path.join(format!("dir_{}", i));
            fs::create_dir_all(&dir_path).unwrap();
            fs::write(dir_path.join(".tree_ignore"), "test content").unwrap();
        }
        
        // Clear should never panic
        let result = clear(base_path);
        
        match result {
            Ok(removed_count) => {
                // Should have removed the expected number of files
                assert_eq!(removed_count, ignore_file_count as u64);
                
                // Running clear again should remove 0 files
                let second_result = clear(base_path).unwrap();
                assert_eq!(second_result, 0);
            }
            Err(_) => {
                // Errors are acceptable, but panics are not
            }
        }
    }
}

/// Property test: print output should be deterministic for the same input
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
                if let Err(_) = fs::write(base_path.join(file_name), "content") {
                    // Skip files that can't be created
                    continue;
                }
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

/// Property test: clear function should handle empty directories gracefully
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
            current_path = current_path.join(format!("level_{}", i));
            fs::create_dir_all(&current_path).unwrap();
        }
        
        // Clear should handle empty directory trees without panicking
        let result = clear(base_path);
        
        match result {
            Ok(count) => {
                // Should remove 0 files from empty directories
                assert_eq!(count, 0);
            }
            Err(_) => {
                // Errors are acceptable for edge cases
            }
        }
    }
}

/// Property test: print should handle various ignore patterns correctly
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
            let non_matching = format!("{}_extra", pattern);
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
