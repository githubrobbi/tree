// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Robert Nio

//! # Tree CLI Application
//!
//! A modern, fast command-line directory tree printer with intelligent ignore
//! pattern support and seamless `.gitignore` integration.
//!
//! ## Overview
//!
//! This binary provides a user-friendly command-line interface to the `tree`
//! library, offering functionality similar to the classic Unix `tree` command
//! but with modern Rust performance and enhanced ignore pattern support.
//!
//! ## Features
//!
//! - **Unicode tree visualization** with clean box-drawing characters
//! - **Automatic `.gitignore` integration** respects existing ignore patterns
//! - **Custom `.tree_ignore` files** for project-specific filtering
//! - **Cleanup functionality** to remove generated ignore files
//! - **Cross-platform support** works on Windows, macOS, and Linux
//! - **Fast performance** with efficient directory traversal
//!
//! ## Usage Examples
//!
//! ```bash
//! # Print current directory tree
//! tree
//!
//! # Print specific directory
//! tree /path/to/project
//!
//! # Clean up .tree_ignore files
//! tree --clear
//! tree -c
//! ```
//!
//! ## Architecture
//!
//! This CLI is a thin wrapper around the `tree` library, handling:
//! - Command-line argument parsing with `clap`
//! - Error formatting and user-friendly messages
//! - Exit code management
//! - Output formatting to stdout
//!
//! The actual tree generation and file management is delegated to the
//! library functions for better separation of concerns and testability.

use anyhow::Result;
use clap::Parser;
use std::path::PathBuf;

/// Command-line interface configuration for the tree application.
///
/// This struct defines all available command-line options and arguments
/// using the `clap` derive API for automatic help generation and parsing.
///
/// ## Design Philosophy
///
/// The CLI is designed to be simple and intuitive:
/// - **Sensible defaults** - Works without any arguments
/// - **Clear options** - Self-documenting flag names
/// - **Unix conventions** - Follows standard CLI patterns
/// - **Minimal complexity** - Only essential options exposed
///
/// ## Examples
///
/// ```bash
/// # Default usage (current directory)
/// tree
///
/// # Specific directory
/// tree /path/to/project
///
/// # Cleanup mode
/// tree --clear
/// tree -c
/// ```
#[derive(Parser, Debug)]
#[command(name = "tree")]
#[command(about = "A fast, modern directory tree printer with intelligent ignore patterns")]
#[command(long_about = "
Tree is a modern directory tree printer written in Rust. It automatically
respects .gitignore files and supports custom .tree_ignore patterns for
fine-grained control over what gets displayed.

Features:
  • Unicode tree visualization with clean box-drawing characters
  • Automatic .gitignore integration
  • Custom .tree_ignore files for project-specific filtering
  • Fast performance with efficient directory traversal
  • Cross-platform support (Windows, macOS, Linux)

Examples:
  tree                    Print current directory tree
  tree /path/to/project   Print specific directory tree
  tree --clear            Remove all .tree_ignore files
")]
#[command(version)]
struct Cli {
    /// Directory path to generate tree for.
    ///
    /// Specifies the root directory to start tree generation from.
    /// Must be an existing directory. Defaults to current directory if not specified.
    #[arg(default_value = ".", value_name = "PATH")]
    path: PathBuf,

    /// Clear all `.tree_ignore` files created by previous runs.
    ///
    /// Recursively removes all `.tree_ignore` files from the specified directory
    /// and its subdirectories. Useful for cleaning up after development or
    /// resetting ignore patterns. Reports the number of files removed.
    #[arg(long, short = 'c')]
    clear: bool,
}

/// Application entry point and main execution logic.
///
/// This function orchestrates the entire CLI application flow:
/// 1. **Argument parsing** - Uses clap to parse command-line arguments
/// 2. **Mode selection** - Determines whether to print tree or clear files
/// 3. **Library delegation** - Calls appropriate tree library functions
/// 4. **Error handling** - Propagates errors with user-friendly messages
/// 5. **Output formatting** - Ensures clean, consistent output
///
/// ## Error Handling Strategy
///
/// The function uses `anyhow::Result` for simplified error handling and
/// propagation. All errors from the tree library are automatically converted
/// to user-friendly messages with full context preservation.
///
/// ## Exit Behavior
///
/// - **Success**: Returns `Ok(())` and exits with code 0
/// - **Error**: Returns `Err(...)` and exits with code 1 (handled by anyhow)
///
/// ## Performance Notes
///
/// The main function itself has minimal overhead - all heavy lifting is
/// delegated to the optimized library functions. Memory usage is bounded
/// by the tree library's streaming implementation.
fn main() -> Result<()> {
    let cli = Cli::parse();

    if cli.clear {
        // Clear mode: Remove all .tree_ignore files and report count
        let removed = tree::clear(&cli.path)?;
        println!("Removed {removed} .tree_ignore file(s)");
    } else {
        // Print mode: Generate and display directory tree
        tree::print(&cli.path, &mut std::io::stdout())?;
    }

    Ok(())
}
