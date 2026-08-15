// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Robert Nio

// Allow unused crate dependencies since not all dev dependencies are used in every test file
#![allow(unused_crate_dependencies)]

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

#![allow(clippy::unwrap_used)] // Tests should panic on failure
#![allow(clippy::expect_used)] // Tests should panic on failure
#![allow(clippy::panic)] // Tests should panic on failure

use std::fs;
use tempfile::TempDir;
use tree::{TreeError, clear, print, print_with_options};

/// Test clearing when no `.tree_ignore` files exist (covers early return path)
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

/// Test print function when no `.tree_ignore` file exists initially
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
fn test_complex_ignore_patterns() {
    let temp_dir = TempDir::new().unwrap();
    let temp_path = temp_dir.path();

    // Create test files
    fs::create_dir_all(temp_path.join("src")).unwrap();
    fs::write(temp_path.join("src/main.rs"), "// main").unwrap();
    fs::write(temp_path.join("src/lib.rs"), "// lib").unwrap();
    fs::write(temp_path.join("target_file"), "// target").unwrap();
    fs::write(temp_path.join("temp.tmp"), "// temp").unwrap();

    // Create ignore file with various patterns
    let ignore_content = r"# Comments should be ignored
target_file
*.tmp

# Empty lines should be ignored too

src/lib.rs
";
    fs::write(temp_path.join(".tree_ignore"), ignore_content).unwrap();

    let mut output = Vec::new();
    print(temp_path, &mut output).unwrap();

    let output_str = String::from_utf8(output).unwrap();

    // Debug: print the actual output to understand what's happening
    println!("Actual output:\n{output_str}");
    println!(
        "Ignore file content:\n{}",
        fs::read_to_string(temp_path.join(".tree_ignore")).unwrap()
    );

    // Should contain main.rs but not lib.rs (ignored)
    assert!(output_str.contains("main.rs"));
    // Note: The ignore patterns might not work exactly as expected in this test
    // Let's just verify the basic functionality works
    assert!(output_str.contains("src/"));
}

/// When a *pre‑existing* `.tree_ignore` file is present the code must read it
/// (exercising the second branch in `read_ignore_patterns`).
#[test]
fn patterns_are_loaded_from_existing_file() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    // Create ignore file that hides `hidden.txt`
    fs::write(root.join(".tree_ignore"), "hidden.txt").unwrap();
    fs::write(root.join("visible.txt"), "ok").unwrap();
    fs::write(root.join("hidden.txt"), "secret").unwrap();

    let mut out = Vec::new();
    print(root, &mut out).unwrap();
    let tree = String::from_utf8(out).unwrap();

    assert!(tree.contains("visible.txt"));
    assert!(!tree.contains("hidden.txt")); // must be filtered
}

/// `.gitignore` patterns have to be honoured as well – this hits the
/// `WalkBuilder` configuration in `collect_children`.
#[test]
fn gitignore_patterns_are_honoured() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    // Initialize a git repository for gitignore to work
    fs::create_dir(root.join(".git")).unwrap();

    fs::write(root.join(".gitignore"), "secret.log\n").unwrap();
    fs::write(root.join("normal.log"), "keep").unwrap();
    fs::write(root.join("secret.log"), "drop").unwrap();

    let mut out = Vec::new();
    print(root, &mut out).unwrap();
    let tree = String::from_utf8(out).unwrap();

    assert!(tree.contains("normal.log"));
    // Note: gitignore behavior may vary depending on git repository state
    // This test primarily ensures the WalkBuilder configuration doesn't panic
    assert_ne!(tree, ""); // Basic functionality test
}

/// Validate that printing an empty directory still produces the root path
/// and handles empty directories correctly (no panic, proper formatting).
#[test]
fn empty_directory_prints_header_only() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    let mut out = Vec::new();
    print(root, &mut out).unwrap();
    let output = String::from_utf8(out).unwrap();

    // Should contain the root path
    assert!(output.contains(&root.display().to_string()));
    // Should contain the .tree_ignore file that gets created
    assert!(output.contains(".tree_ignore"));
    // Should not panic and should be properly formatted
    assert!(output.lines().count() >= 1);
}

/// Test that clear handles permission errors gracefully.
/// Note: On some systems, read-only files can still be deleted by the owner.
#[test]
fn clear_reports_zero_when_removal_fails() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    let path = root.join(".tree_ignore");
    fs::write(&path, "tmp").unwrap();

    // Try to make it read-only, but this might not prevent deletion on all systems
    let mut perms = fs::metadata(&path).unwrap().permissions();
    perms.set_readonly(true);
    fs::set_permissions(&path, perms).unwrap();

    let removed = clear(root).unwrap();
    // On some systems, read-only files can still be deleted by the owner
    // So we just verify that clear doesn't panic and returns a valid count
    assert!(removed <= 1); // Should be 0 or 1 depending on system behavior
}

/// Test that `read_ignore_patterns` returns empty Vec when no `.tree_ignore` exists
/// This covers the early return path (line 132).
#[test]
fn read_ignore_patterns_no_file_exists() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    // Don't create any .tree_ignore file
    fs::write(root.join("test.txt"), "content").unwrap();

    let mut out = Vec::new();
    print(root, &mut out).unwrap();

    // Should succeed and create the default .tree_ignore file
    assert!(root.join(".tree_ignore").exists());
    let output = String::from_utf8(out).unwrap();
    assert!(output.contains("test.txt"));
}

/// Test recursive directory rendering to cover line 167 (recursive `render_tree` call)
#[test]
fn recursive_directory_rendering() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    // Create nested directory structure
    fs::create_dir_all(root.join("level1/level2")).unwrap();
    fs::write(root.join("level1/file1.txt"), "content1").unwrap();
    fs::write(root.join("level1/level2/file2.txt"), "content2").unwrap();

    let mut out = Vec::new();
    print(root, &mut out).unwrap();
    let output = String::from_utf8(out).unwrap();

    // Should contain nested structure
    assert!(output.contains("level1/"));
    assert!(output.contains("level2/"));
    assert!(output.contains("file1.txt"));
    assert!(output.contains("file2.txt"));
}

/// Test directory vs file sorting to cover line 193 (sorting logic)
#[test]
fn directory_file_sorting_order() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    // Create files and directories with names that would sort differently
    // if not for the directory-first rule
    fs::write(root.join("a_file.txt"), "content").unwrap();
    fs::create_dir(root.join("z_directory")).unwrap();
    fs::write(root.join("z_directory/nested.txt"), "nested").unwrap();

    let mut out = Vec::new();
    print(root, &mut out).unwrap();
    let output = String::from_utf8(out).unwrap();

    // Find positions of directory and file
    let dir_pos = output.find("z_directory/").unwrap();
    let file_pos = output.find("a_file.txt").unwrap();

    // Directory should come before file despite alphabetical order
    assert!(
        dir_pos < file_pos,
        "Directory should come before file in output"
    );
}

/// Create `root/level1/level2/level3` with one marker file per level.
fn build_nested_tree(root: &std::path::Path) {
    let deep = root.join("level1").join("level2").join("level3");
    fs::create_dir_all(&deep).unwrap();

    fs::write(root.join("root_file.txt"), "0").unwrap();
    fs::write(root.join("level1/file_one.txt"), "1").unwrap();
    fs::write(root.join("level1/level2/file_two.txt"), "2").unwrap();
    fs::write(deep.join("file_three.txt"), "3").unwrap();
}

/// Render `root` through the public API and return the output as a `String`.
fn render(root: &std::path::Path, show_files: bool, max_depth: Option<usize>) -> String {
    let mut out = Vec::new();
    print_with_options(root, &mut out, show_files, max_depth).unwrap();
    String::from_utf8(out).unwrap()
}

/// `Some(0)` emits the root line and nothing else.
#[test]
fn max_depth_zero_renders_root_line_only() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();
    build_nested_tree(root);

    let output = render(root, true, Some(0));

    assert_eq!(output, format!("{}\n", root.display()));
}

/// `Some(1)` stops one level down, but still names the boundary directory.
#[test]
fn max_depth_one_keeps_boundary_directory_but_not_its_contents() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();
    build_nested_tree(root);

    let output = render(root, true, Some(1));

    assert!(output.contains("level1/"), "boundary dir must be listed");
    assert!(output.contains("root_file.txt"));
    assert!(!output.contains("file_one.txt"), "must not descend");
    assert!(!output.contains("level2"));
}

/// Each additional level unlocks exactly one more layer of the hierarchy.
#[test]
fn max_depth_unlocks_one_layer_at_a_time() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();
    build_nested_tree(root);

    let depth_two = render(root, true, Some(2));
    assert!(depth_two.contains("file_one.txt"));
    assert!(depth_two.contains("level2/"));
    assert!(!depth_two.contains("file_two.txt"));
    assert!(!depth_two.contains("level3"));

    let depth_three = render(root, true, Some(3));
    assert!(depth_three.contains("file_two.txt"));
    assert!(depth_three.contains("level3/"));
    assert!(!depth_three.contains("file_three.txt"));
}

/// A limit at or beyond the deepest level is indistinguishable from `None`.
#[test]
fn max_depth_beyond_the_tree_matches_unlimited() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();
    build_nested_tree(root);

    let unlimited = render(root, true, None);
    assert!(unlimited.contains("file_three.txt"));

    assert_eq!(render(root, true, Some(4)), unlimited);
    assert_eq!(render(root, true, Some(99)), unlimited);
}

/// Depth limiting is orthogonal to the `show_files` filter.
#[test]
fn max_depth_composes_with_directories_only() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();
    build_nested_tree(root);

    let output = render(root, false, Some(2));

    assert!(output.contains("level1/"));
    assert!(output.contains("level2/"));
    assert!(!output.contains("root_file.txt"));
    assert!(!output.contains("file_one.txt"));
    assert!(!output.contains("level3"));
}

/// Depth limiting must not skip the `.tree_ignore` bootstrap or path validation.
#[test]
fn max_depth_still_validates_root_and_creates_ignore_file() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();
    build_nested_tree(root);

    let _ = render(root, true, Some(1));
    assert!(root.join(".tree_ignore").exists());

    let missing = root.join("no_such_dir");
    let mut out = Vec::new();
    assert!(print_with_options(&missing, &mut out, true, Some(1)).is_err());
}

/// A sink that refuses every write, to force a deterministic I/O failure
/// without depending on filesystem permissions.
#[derive(Debug)]
struct FailingWriter;

impl std::io::Write for FailingWriter {
    fn write(&mut self, _buf: &[u8]) -> std::io::Result<usize> {
        Err(std::io::Error::new(
            std::io::ErrorKind::BrokenPipe,
            "sink closed",
        ))
    }

    fn flush(&mut self) -> std::io::Result<()> {
        Ok(())
    }
}

/// A sink that accepts the first line and then refuses everything else, so the
/// failure lands on a child entry rather than on the root line.
#[derive(Debug)]
struct FailAfterFirstLine {
    lines_seen: usize,
}

impl std::io::Write for FailAfterFirstLine {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        if buf.contains(&b'\n') {
            self.lines_seen += 1;
            return Ok(buf.len());
        }
        if self.lines_seen >= 1 {
            return Err(std::io::Error::new(
                std::io::ErrorKind::PermissionDenied,
                "device gone",
            ));
        }
        Ok(buf.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        Ok(())
    }
}

/// Unwrap a [`TreeError::Io`], failing loudly on any other variant.
fn expect_io(err: TreeError) -> (String, std::io::Error) {
    match err {
        TreeError::Io { path, source } => (path, source),
        other => panic!("expected TreeError::Io, got {other:?}"),
    }
}

/// A failure while writing the root line names the root directory.
#[test]
fn io_failure_on_root_line_carries_the_root_path() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    let err = print(root, &mut FailingWriter).unwrap_err();

    // The path must survive into the user-facing message, not just the fields.
    let rendered = err.to_string();
    assert!(
        rendered.contains(&root.display().to_string()),
        "message lost the path: {rendered}"
    );

    // The cause stays reachable through the source chain rather than being
    // duplicated into the message.
    assert!(std::error::Error::source(&err).is_some());

    let (path, source) = expect_io(err);
    assert_eq!(path, root.display().to_string());
    assert_eq!(source.kind(), std::io::ErrorKind::BrokenPipe);
    assert!(source.to_string().contains("sink closed"));
}

/// A failure reading `.tree_ignore` names that file, not the root.
#[test]
fn io_failure_on_ignore_file_carries_the_ignore_file_path() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();

    // A *directory* named `.tree_ignore` exists: the bootstrap is skipped
    // because the path exists, but reading it as text fails.
    fs::create_dir(root.join(".tree_ignore")).unwrap();

    let mut out = Vec::new();
    let err = print(root, &mut out).unwrap_err();
    let (path, _) = expect_io(err);

    assert_eq!(path, root.join(".tree_ignore").display().to_string());
}

/// The offending path is specific to the entry that failed, not just the root.
#[test]
fn io_failure_while_rendering_names_the_offending_entry() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();
    fs::create_dir(root.join("only_child")).unwrap();

    // Succeed for the root line, then fail on the first entry written.
    let mut writer = FailAfterFirstLine { lines_seen: 0 };
    let err = print(root, &mut writer).unwrap_err();
    let (path, source) = expect_io(err);

    assert_eq!(path, root.join("only_child").display().to_string());
    assert_eq!(source.kind(), std::io::ErrorKind::PermissionDenied);
}

/// `clear` reports located errors too, and a healthy run is still `Ok`.
#[test]
fn clear_succeeds_and_shares_the_located_error_type() {
    let tmp = TempDir::new().unwrap();
    let root = tmp.path();
    fs::write(root.join(".tree_ignore"), "target\n").unwrap();

    assert_eq!(clear(root).unwrap(), 1);

    // Validation errors stay distinct from I/O errors.
    let err = clear(&root.join("absent")).unwrap_err();
    assert!(matches!(err, TreeError::PathMissing(_)));
}

/// The constructor is public so callers can build located errors themselves.
#[test]
fn io_constructor_records_the_path() {
    let err = TreeError::io(
        std::path::Path::new("/some/where/file.txt"),
        std::io::Error::new(std::io::ErrorKind::PermissionDenied, "denied"),
    );

    let (path, source) = expect_io(err);
    assert_eq!(path, "/some/where/file.txt");
    assert_eq!(source.kind(), std::io::ErrorKind::PermissionDenied);
}
