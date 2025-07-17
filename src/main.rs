//! # Tree CLI Tool
//!
//! A simple command-line tool to print directory trees with configurable ignore patterns.
//!
//! ## Features
//!
//! - Clean, formatted directory tree output
//! - Respects `.gitignore` files automatically
//! - Uses configurable `.tree_ignore` files for customizable ignore patterns
//! - Recursive clear functionality to remove all generated ignore files from directory trees
//! - Fast performance with Rust
//! - Simple command-line interface

/// Tree printer module containing the core tree printing functionality
mod tree_printer;

use std::path::PathBuf;
use std::fs;
use anyhow::Result;
use clap::Parser;

/// A simple CLI tool to print directory trees
#[derive(Parser)]
#[command(name = "tree")]
#[command(about = "A simple directory tree printer")]
#[command(version = "0.1.0")]
struct Cli {
    /// Directory path to print the tree for
    #[arg(default_value = ".")]
    path: PathBuf,

    /// Clear all `.tree_ignore` files created by previous runs
    #[arg(long, short)]
    clear: bool,
}

/// Clear all `.tree_ignore` files in the given directory and its subdirectories
fn clear_ignore_files(path: &PathBuf) -> Result<()> {
    // Validate the path exists
    if !path.exists() {
        anyhow::bail!("Path '{}' does not exist", path.display());
    }

    if !path.is_dir() {
        anyhow::bail!("Path '{}' is not a directory", path.display());
    }

    println!("Searching for .tree_ignore files in {} and all subdirectories...", path.display());

    let mut count = 0;
    let mut directories_scanned = 0;
    let mut errors = Vec::new();

    // Walk through all directories recursively and find .tree_ignore files
    for entry in walkdir::WalkDir::new(path)
        .follow_links(false)  // Don't follow symbolic links to avoid infinite loops
    {
        match entry {
            Ok(entry) => {
                let file_path = entry.path();

                // Count directories we're scanning
                if file_path.is_dir() {
                    directories_scanned += 1;
                }

                // Check if this is a .tree_ignore file
                if file_path.file_name() == Some(std::ffi::OsStr::new(".tree_ignore")) {
                    match fs::remove_file(file_path) {
                        Ok(()) => {
                            println!("Removed: {}", file_path.display());
                            count += 1;
                        }
                        Err(e) => {
                            let error_msg = format!("Failed to remove {}: {}", file_path.display(), e);
                            eprintln!("Warning: {error_msg}");
                            errors.push(error_msg);
                        }
                    }
                }
            }
            Err(e) => {
                let error_msg = format!("Error accessing path: {e}");
                eprintln!("Warning: {error_msg}");
                errors.push(error_msg);
                // Continue processing other entries instead of failing completely
            }
        }
    }

    // Print summary
    println!("\nScan complete:");
    println!("  Directories scanned: {directories_scanned}");
    println!("  .tree_ignore files found and removed: {count}");

    if !errors.is_empty() {
        println!("  Errors encountered: {}", errors.len());
        println!("\nNote: Some files could not be processed due to permission or access issues.");
    }

    if count == 0 && errors.is_empty() {
        println!("\nNo .tree_ignore files found in the specified directory tree.");
    } else if count > 0 {
        println!("\nSuccessfully cleaned up {count} .tree_ignore file(s).");
    }

    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // Handle clear mode
    if cli.clear {
        return clear_ignore_files(&cli.path);
    }

    // Verify the path exists and is a directory for normal tree printing
    if !cli.path.exists() {
        anyhow::bail!("Path '{}' does not exist", cli.path.display());
    }

    if !cli.path.is_dir() {
        anyhow::bail!("Path '{}' is not a directory", cli.path.display());
    }

    // Print the directory tree
    tree_printer::print_directory_tree(&cli.path)?;

    Ok(())
}
