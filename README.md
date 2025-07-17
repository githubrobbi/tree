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

This project is dual-licensed under:
- Mozilla Public License 2.0 (MPL-2.0)
- Commercial License (LicenseRef-TTAPI-Commercial)

See the source files for full license information.
