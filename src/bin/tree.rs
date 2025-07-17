// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Robert Nio

//! Tree CLI binary
//!
//! A command-line interface for the tree library that prints directory trees
//! with configurable ignore patterns.

use anyhow::Result;
use clap::Parser;
use std::path::PathBuf;

/// Tree CLI tool for printing directory structures
#[derive(Parser, Debug)]
#[command(name = "tree")]
#[command(about = "A simple CLI tool to print directory trees with configurable ignore patterns")]
#[command(version)]
struct Cli {
    /// Directory path to print tree for
    #[arg(default_value = ".")]
    path: PathBuf,

    /// Clear all `.tree_ignore` files created by previous runs
    #[arg(long, short = 'c')]
    clear: bool,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    if cli.clear {
        let removed = tree::clear(&cli.path)?;
        println!("Removed {removed} .tree_ignore file(s)");
    } else {
        tree::print(&cli.path, &mut std::io::stdout())?;
    }

    Ok(())
}
