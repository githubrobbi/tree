# Tree CLI Tool

A simple command-line tool to print directory trees, written in Rust.

## Features

- 🌳 Clean, formatted directory tree output
- 🚫 Respects `.gitignore` files automatically
- 📁 Filters out common build/cache directories (`target`, `node_modules`, `.git`, etc.)
- 📝 Uses configurable `.tree_ignore` files for customizable ignore patterns
- 🧹 Recursive clear functionality to remove all generated ignore files from directory trees
- ⚡ Fast performance with Rust
- 🎯 Simple command-line interface

## Installation

### From Source

```bash
git clone <repository-url>
cd tree
cargo build --release
```

The binary will be available at `target/release/tree`.

## Usage

### Command Line Interface

```bash
# Print tree for current directory
tree

# Print tree for specific directory
tree /path/to/directory

# Clear all .tree_ignore files created by previous runs (recursively from current directory)
tree --clear

# Clear .tree_ignore files in a specific directory and all its subdirectories
tree --clear /path/to/directory

# Show help
tree --help
```

### Library Usage

Add to your `Cargo.toml`:
```toml
[dependencies]
tree = "0.1.46"
```

Use in your Rust code:
```rust
use std::path::Path;
use tree::{print, clear};

fn main() -> Result<(), tree::TreeError> {
    // Print directory tree to stdout
    let mut stdout = std::io::stdout();
    print(Path::new("."), &mut stdout)?;

    // Clear all .tree_ignore files
    let removed_count = clear(Path::new("."))?;
    println!("Removed {} .tree_ignore files", removed_count);

    Ok(())
}
```

## Example Output

```
.
├── .qodo
├── src
│   ├── main.rs
│   └── tree_printer.rs
├── .gitignore
├── Cargo.lock
└── Cargo.toml
```

## Default Ignore Patterns

When a `.tree_ignore` file is created, it includes these default patterns:

**Build and compilation outputs:** `target`, `build`, `dist`, `out`
**Dependencies:** `node_modules`, `vendor`, `.pnpm-store`
**Version control:** `.git`, `.svn`, `.hg`
**IDE files:** `.vscode`, `.idea`, `.idea.old`, `*.swp`, `*.swo`, `*~`
**OS files:** `.DS_Store`, `Thumbs.db`
**Temporary directories:** `tmp`, `temp`, `cache`, `.cache`
**Legacy directories:** `old_do_not_use`, `backup`

Additionally, the tool respects `.gitignore` files in your project.

## Configuration Files

The tree tool uses `.tree_ignore` configuration files to determine which directories and files to ignore. These files work as follows:

### Automatic Creation
- When you run `tree` in a directory without a `.tree_ignore` file, one is automatically created with sensible defaults
- The file contains common ignore patterns for build outputs, dependencies, version control, etc.

### Customization
- You can edit the `.tree_ignore` file to add, remove, or modify ignore patterns
- Each line represents one pattern (exact name matches only)
- Lines starting with `#` are comments and are ignored
- Empty lines are ignored

### Example `.tree_ignore` content:
```
# Tree ignore patterns configuration file
# Add one pattern per line (exact name matches only)

# Build and compilation outputs
target
build
node_modules

# Version control
.git
.idea

# Custom patterns
my_custom_dir
temp_files
```

### Pattern Matching
- Patterns match exact directory/file names (not paths)
- For example, `target` will ignore any directory named "target" at any level
- Wildcards and regex are not currently supported

## Clear Functionality

The `--clear` flag provides a powerful way to clean up all `.tree_ignore` files from your directory structure:

### Features:
- **Recursive traversal**: Searches through the entire directory tree starting from the specified path
- **Comprehensive scanning**: Finds all `.tree_ignore` files regardless of depth
- **Detailed feedback**: Shows exactly which files were removed and provides scan statistics
- **Error handling**: Gracefully handles permission errors and inaccessible directories
- **Safe operation**: Only removes `.tree_ignore` files, never touches other files

### Example output:
```
$ tree --clear
Searching for .tree_ignore files in . and all subdirectories...
Removed: ./.tree_ignore
Removed: ./src/.tree_ignore
Removed: ./tests/fixtures/.tree_ignore

Scan complete:
  Directories scanned: 25
  .tree_ignore files found and removed: 3

Successfully cleaned up 3 .tree_ignore file(s).
```

## Dependencies

- `anyhow` - Error handling
- `ignore` - Gitignore and file filtering
- `clap` - Command-line argument parsing
- `walkdir` - Directory traversal for clear functionality

## License

This project is licensed under the MIT License.

Copyright (c) 2025 Robert Nio

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

See the [LICENSE](LICENSE) file for full license information.
