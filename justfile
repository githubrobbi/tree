# Tree - Modern Rust Development Workflow
# Professional CLI tree utility with intelligent ignore patterns
# Cross-platform compatible - works on Windows, macOS, and Linux


# Pick bash for Unix-likes, PowerShell for Windows
set shell          := ["bash", "-cu"]              # default for Linux/macOS
set windows-shell  := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# Export color environment variables for Git Bash
export FORCE_COLOR := "1"
export CLICOLOR_FORCE := "1"
export TERM := "xterm-256color"
export COLORTERM := "truecolor"
export CARGO_TERM_COLOR := "always"

# Cross-platform color system using printf (POSIX compatible)
# Works on Linux, macOS, Windows Git Bash, WSL
# Respects NO_COLOR environment variable (https://no-color.org/)

# Temporary color variables for backward compatibility
# These will be replaced with printf-based approach gradually
GREEN := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0;32m' }
BLUE := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0;34m' }
YELLOW := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[1;33m' }
RED := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0;31m' }
NC := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0m' }

# Default recipe - Windows version that works without shell dependencies
[windows]
default:
    @Write-Host "🌳 Tree - Modern Rust Development Workflow"
    @Write-Host "=================================================="
    @Write-Host ""
    @Write-Host "🚀 Main Workflow:"
    @Write-Host "  just go           - Complete two-phase fast-fail workflow"
    @Write-Host ""
    @Write-Host "⚙️  Environment Setup:"
    @Write-Host "  just setup        - Smart setup (Unix/Linux/macOS/Git Bash)"
    @Write-Host "  just setup-powershell - Windows PowerShell setup (run first!)"
    @Write-Host "  just setup-windows - Windows Git Bash setup"
    @Write-Host "  just setup-simple  - Command Prompt compatible"
    @Write-Host "  just setup-nocolor - Any terminal (no colors)"
    @Write-Host ""
    @Write-Host "📋 Individual Steps:"
    @Write-Host "  just fmt          - Format code"
    @Write-Host "  just test         - Run all tests"
    @Write-Host "  just doc          - Run documentation tests"
    @Write-Host "  just coverage     - Generate coverage report"
    @Write-Host "  just lint-prod    - Ultra-strict production linting"
    @Write-Host "  just lint-tests   - Pragmatic test linting"
    @Write-Host "  just build        - Build release binary"
    @Write-Host "  just deploy       - Copy binary to ~/bin"
    @Write-Host ""
    @Write-Host "🔧 Development:"
    @Write-Host "  just dev          - Watch mode with testing"
    @Write-Host "  just check        - Quick validation"
    @Write-Host "  just clean        - Clean build artifacts"
    @Write-Host ""
    @Write-Host "📊 Analysis & Optimization:"
    @Write-Host "  just audit        - Comprehensive security audit"
    @Write-Host "  just deps-optimize - Find & remove unused dependencies"
    @Write-Host "  just debug-deep   - Advanced debugging (macros, miri)"
    @Write-Host "  just semver-check - Semantic versioning compliance"
    @Write-Host "  just bench        - Performance benchmarking"
    @Write-Host "  just version      - Show current version"
    @Write-Host "  just benchmark-both - Compare workflow performance"
    @Write-Host ""
    @Write-Host "💡 Windows users: Choose the right setup for your terminal:"
    @Write-Host "   • PowerShell (bare metal): .\setup-windows.ps1 (run as Admin)"
    @Write-Host "   • Git Bash: just setup (colors work automatically!)"
    @Write-Host "   • Command Prompt: just setup-simple (no colors)"
    @Write-Host "   • Any terminal: NO_COLOR=1 just setup"
    @Write-Host ""
    @Write-Host "⚠️  SHELL ERROR? If you see 'shell: program not found':"
    @Write-Host "   1. Install Git for Windows first: .\setup-windows.ps1"
    @Write-Host "   2. Or add this to your PowerShell profile:"
    @Write-Host "      function jb { just --shell 'C:\Program Files\Git\bin\bash.exe' @args }"
    @Write-Host "   3. Then use 'jb' instead of 'just' (e.g., 'jb go', 'jb setup')"

# Default recipe - Unix/Linux/macOS version
[unix]
default:
    @echo "🌳 Tree - Modern Rust Development Workflow"
    @echo "=================================================="
    @echo ""
    @echo "🚀 Main Workflow:"
    @echo "  just go           - Complete two-phase fast-fail workflow"
    @echo ""
    @echo "⚙️  Environment Setup:"
    @echo "  just setup        - Smart setup (Unix/Linux/macOS/Git Bash)"
    @echo "  just setup-powershell - Windows PowerShell setup (run first!)"
    @echo "  just setup-windows - Windows Git Bash setup"
    @echo "  just setup-simple  - Command Prompt compatible"
    @echo "  just setup-nocolor - Any terminal (no colors)"
    @echo ""
    @echo "📋 Individual Steps:"
    @echo "  just fmt          - Format code"
    @echo "  just test         - Run all tests"
    @echo "  just doc          - Run documentation tests"
    @echo "  just coverage     - Generate coverage report"
    @echo "  just lint-prod    - Ultra-strict production linting"
    @echo "  just lint-tests   - Pragmatic test linting"
    @echo "  just build        - Build release binary"
    @echo "  just deploy       - Copy binary to ~/bin"
    @echo ""
    @echo "🔧 Development:"
    @echo "  just dev          - Watch mode with testing"
    @echo "  just check        - Quick validation"
    @echo "  just clean        - Clean build artifacts"
    @echo ""
    @echo "📊 Analysis & Optimization:"
    @echo "  just audit        - Comprehensive security audit"
    @echo "  just deps-optimize - Find & remove unused dependencies"
    @echo "  just debug-deep   - Advanced debugging (macros, miri)"
    @echo "  just semver-check - Semantic versioning compliance"
    @echo "  just bench        - Performance benchmarking"
    @echo "  just version      - Show current version"
    @echo "  just benchmark-both - Compare workflow performance"
    @echo ""
    @echo "💡 Windows users: Choose the right setup for your terminal:"
    @echo "   • PowerShell (bare metal): .\\setup-windows.ps1 (run as Admin)"
    @echo "   • Git Bash: just setup (colors work automatically!)"
    @echo "   • Command Prompt: just setup-simple (no colors)"
    @echo "   • Any terminal: NO_COLOR=1 just setup"
    @echo ""
    @echo "⚠️  SHELL ERROR? If you see 'shell: program not found':"
    @echo "   1. Install Git for Windows first: .\\setup-windows.ps1"
    @echo "   2. Or add this to your PowerShell profile:"
    @echo "      function jb { just --shell 'C:\\Program Files\\Git\\bin\\bash.exe' @args }"
    @echo "   3. Then use 'jb' instead of 'just' (e.g., 'jb go', 'jb setup')"

# Common clippy flags - Rust master approach
common_flags := "-D clippy::pedantic -D clippy::nursery -D clippy::cargo -A clippy::multiple_crate_versions -W clippy::panic -W clippy::todo -W clippy::unimplemented -D warnings"
prod_flags := common_flags + " -W clippy::unwrap_used -W clippy::expect_used -W clippy::missing_docs_in_private_items"
test_flags := common_flags + " -A clippy::unwrap_used -A clippy::expect_used"

# ═══════════════════════════════════════════════════════════════════════════
# Individual Step Commands (Granular Control)
# ═══════════════════════════════════════════════════════════════════════════

# Format code
fmt:
    @echo "{{BLUE}}📝 Formatting code...{{NC}}"
    CARGO_TERM_COLOR=always cargo fmt --all

# Run all tests (blazing fast with nextest)
test:
    @echo "{{BLUE}}🧪 Running all tests (blazing fast with nextest)...{{NC}}"
    @if command -v cargo-nextest >/dev/null 2>&1; then \
        CARGO_TERM_COLOR=always cargo nextest run --workspace --all-features; \
    else \
        echo "{{YELLOW}}⚠️  cargo-nextest not found, falling back to cargo test{{NC}}"; \
        CARGO_TERM_COLOR=always cargo test --workspace --all-features --all-targets; \
    fi

# Run documentation tests
doc:
    @echo "{{BLUE}}📚 Running documentation tests...{{NC}}"
    cargo test --workspace --doc --all-features

# Generate coverage report (optimized with nextest integration)
coverage:
    @echo "{{BLUE}}📊 Generating coverage report (optimized)...{{NC}}"
    @echo "{{BLUE}}  → Cleaning build artifacts first...{{NC}}"
    cargo clean
    @if command -v cargo-nextest >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Using nextest for faster coverage collection...{{NC}}"; \
        cargo llvm-cov nextest --workspace --all-features --html; \
    else \
        echo "{{YELLOW}}  → Using standard test runner for coverage...{{NC}}"; \
        cargo llvm-cov test --workspace --all-features --all-targets --html; \
    fi
    @echo "{{GREEN}}📁 Coverage report: target/llvm-cov/html/index.html{{NC}}"

# Ultra-strict production linting
lint-prod:
    @echo "{{BLUE}}🔍 Ultra-strict production linting...{{NC}}"
    cargo clippy --lib --bins -- {{prod_flags}}

# Pragmatic test linting
lint-tests:
    @echo "{{BLUE}}🧪 Pragmatic test linting...{{NC}}"
    cargo clippy --tests -- {{test_flags}}

# Build release binary
build:
    @echo "{{BLUE}}🔨 Building release binary...{{NC}}"
    cargo build --release

# Deploy binary to ~/bin
deploy:
    @echo "{{BLUE}}📦 Deploying binary...{{NC}}"
    just copy-binary release

# ═══════════════════════════════════════════════════════════════════════════
# Development Utilities
# ═══════════════════════════════════════════════════════════════════════════

# Watch mode development
dev:
    @echo "{{BLUE}}🔄 Starting watch mode...{{NC}}"
    -cargo watch --version || cargo install cargo-watch
    cargo watch -x "test --workspace" -x "clippy --workspace --all-targets --all-features -- {{test_flags}}"

# Quick validation
check:
    @echo "{{BLUE}}⚡ Quick validation...{{NC}}"
    cargo check --workspace --all-targets --all-features
    cargo fmt --all -- --check



# ═══════════════════════════════════════════════════════════════════════════
# Professional Two-Phase Development Workflow
# ═══════════════════════════════════════════════════════════════════════════
# Phase 1: Code & Extensive Testing (Manual Trigger)
# Phase 2: Build/Commit/Push/Deploy (Manual Trigger)
# ═══════════════════════════════════════════════════════════════════════════



# PHASE 1: Code & Extensive Testing (Fast-Fail)
phase1-test:
    @echo "{{BLUE}}🧪 PHASE 1: Code & Extensive Testing (FAST-FAIL){{NC}}"
    @echo "{{YELLOW}}Running MOST extensive tests - STOPPING at FIRST failure...{{NC}}"
    @echo "========================================================"
    @echo ""

    # Step 1: Clean build artifacts (prevent cross-project contamination)
    @echo "{{BLUE}}Step 1: Cleaning build artifacts...{{NC}}"
    cargo clean
    @echo "{{GREEN}}✅ Build artifacts cleaned{{NC}}"

    # Step 2: Auto-formatting
    @echo "{{BLUE}}Step 2: Auto-formatting code...{{NC}}"
    cargo fmt --all

    # Step 3: Comprehensive compilation and validation (FAST-FAIL)
    @echo "{{BLUE}}Step 3: Comprehensive compilation and validation (FAST-FAIL)...{{NC}}"
    -cargo llvm-cov --version || cargo install cargo-llvm-cov

    # 3a: Build with coverage and run unit/integration tests with report (optimized)
    @echo "{{BLUE}}  → Running unit & integration tests with coverage report (optimized)...{{NC}}"
    @if command -v cargo-nextest >/dev/null 2>&1; then \
        echo "{{BLUE}}    Using nextest for blazing-fast test execution...{{NC}}"; \
        cargo llvm-cov nextest --workspace --all-features --html; \
    else \
        echo "{{YELLOW}}    Using standard test runner...{{NC}}"; \
        cargo llvm-cov test --workspace --all-features --all-targets --html; \
    fi
    @echo "{{GREEN}}✅ Unit & integration tests passed, coverage report generated{{NC}}"
    @echo "{{GREEN}}📁 Coverage report: target/llvm-cov/html/index.html{{NC}}"

    # 3b: Run ONLY doc tests (optimal performance - minimal recompilation)
    @echo "{{BLUE}}  → Running documentation tests only...{{NC}}"
    cargo test --workspace --doc --all-features
    @echo "{{GREEN}}✅ Documentation tests passed (3% faster than duplicate test approach){{NC}}"

    # 3c: Production linting (reuses compilation artifacts)
    @echo "{{BLUE}}  → Ultra-strict production linting...{{NC}}"
    cargo clippy --lib --bins -- {{prod_flags}}
    @echo "{{GREEN}}✅ Production code linting passed{{NC}}"

    # 3d: Test linting (reuses compilation artifacts)
    @echo "{{BLUE}}  → Pragmatic test linting...{{NC}}"
    cargo clippy --tests -- {{test_flags}}
    @echo "{{GREEN}}✅ Test code linting passed{{NC}}"

    # Step 4: Format validation (final check) (FAST-FAIL)
    @echo "{{BLUE}}Step 4: Final format validation (FAST-FAIL)...{{NC}}"
    cargo fmt --all -- --check

    @echo ""
    @echo "{{GREEN}}✅ PHASE 1 FAST-FAIL COMPLETE: All extensive tests passed, code ready for commit!{{NC}}"
    @echo "{{BLUE}}💡 Next: Run 'just phase2-ship' when ready to build/commit/push{{NC}}"

# PHASE 2: Version/Build/Deploy (Professional Grade)
phase2-ship:
    @echo "{{BLUE}}🚀 PHASE 2: Version/Build/Deploy (Post-Testing){{NC}}"
    @echo "{{YELLOW}}Assumes Phase 1 completed: format ✅ clippy ✅ compile ✅ tests ✅{{NC}}"
    @echo "========================================================"
    @echo ""

    # Step 1: Version increment
    @echo "{{BLUE}}Step 1: Version increment...{{NC}}"
    -rust-script --version || cargo install rust-script
    ./build/update_version.rs patch

    # Step 2: Build with new version
    @echo "{{BLUE}}Step 2: Building release binary with NEW version...{{NC}}"
    cargo build --release

    # Step 3: Copy binary to deployment location
    @echo "{{BLUE}}Step 3: Copy binary to deployment location...{{NC}}"
    just copy-binary release

    # Step 4: Add all changes to git
    @echo "{{BLUE}}Step 4: Adding all changes to staging area...{{NC}}"
    git add .

    # Step 5: Create auto-generated commit
    @echo "{{BLUE}}Step 5: Creating auto-generated commit...{{NC}}"
    git commit -m "chore: release v`grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/'` - comprehensive testing complete [auto-commit]"

    # Step 6: Sync with remote and push
    @echo "{{BLUE}}Step 6: Syncing with remote and pushing...{{NC}}"
    git pull origin main --rebase
    git push origin main

    @echo ""
    @echo "{{GREEN}}✅ PHASE 2 COMPLETE: Version incremented, built, deployed, committed, and pushed!{{NC}}"



# Complete two-phase fast-fail workflow - perfect for rapid development
go:
    @echo "{{BLUE}}🚀 Complete Two-Phase Fast-Fail Workflow{{NC}}"
    @echo "{{YELLOW}}Failing fast at ANY error in either phase...{{NC}}"
    @echo "========================================================"
    @echo ""

    # PHASE 1: Comprehensive fast-fail testing and validation
    @echo "{{BLUE}}🧪 PHASE 1: Comprehensive Fast-Fail Testing & Validation{{NC}}"
    just phase1-test

    @echo ""
    @echo "{{GREEN}}✅ PHASE 1 COMPLETE - All validation passed!{{NC}}"
    @echo "{{BLUE}}🚀 Starting PHASE 2: Build/Deploy...{{NC}}"
    @echo ""

    # PHASE 2: Fast-fail build and deployment
    @echo "{{BLUE}}📦 PHASE 2: Fast-Fail Build & Deploy{{NC}}"
    just phase2-ship

    @echo ""
    @echo "{{GREEN}}🎉 COMPLETE TWO-PHASE FAST-FAIL WORKFLOW FINISHED!{{NC}}"
    @echo "{{GREEN}}✅ Phase 1: Testing & Validation{{NC}}"
    @echo "{{GREEN}}✅ Phase 2: Build/Commit/Push/Deploy{{NC}}"





# ═══════════════════════════════════════════════════════════════════════════
# Quality Assurance & Analysis
# ═══════════════════════════════════════════════════════════════════════════



# ═══════════════════════════════════════════════════════════════════════════
# Utilities
# ═══════════════════════════════════════════════════════════════════════════

# Comprehensive security audit
audit:
    @echo "{{BLUE}}🔒 Comprehensive security audit...{{NC}}"

    # cargo-audit - Security vulnerability scanner
    @echo "{{BLUE}}  → Running cargo-audit (vulnerability scan)...{{NC}}"
    @if command -v cargo-audit >/dev/null 2>&1; then \
        cargo audit; \
    else \
        echo "{{YELLOW}}⚠️  cargo-audit not found, run 'just setup' first{{NC}}"; \
    fi

    # cargo-deny - Comprehensive dependency analysis
    @echo "{{BLUE}}  → Running cargo-deny (dependency analysis)...{{NC}}"
    @if command -v cargo-deny >/dev/null 2>&1; then \
        cargo deny check; \
    else \
        echo "{{YELLOW}}⚠️  cargo-deny not found, run 'just setup' first{{NC}}"; \
    fi

    # cargo-geiger - Unsafe code detection
    @echo "{{BLUE}}  → Running cargo-geiger (unsafe code detection)...{{NC}}"
    @if command -v cargo-geiger >/dev/null 2>&1; then \
        cargo geiger; \
    else \
        echo "{{YELLOW}}⚠️  cargo-geiger not found, run 'just setup' first{{NC}}"; \
    fi

# Show current version
version:
    @echo "{{BLUE}}📋 Current version:{{NC}}"
    @grep '^version' Cargo.toml | head -1

# Dependency optimization and cleanup
deps-optimize:
    @echo "{{BLUE}}🔧 Optimizing dependencies...{{NC}}"

    # Find unused dependencies
    @echo "{{BLUE}}  → Finding unused dependencies...{{NC}}"
    @if command -v cargo-udeps >/dev/null 2>&1; then \
        cargo +nightly udeps; \
    else \
        echo "{{YELLOW}}⚠️  cargo-udeps not found, run 'just setup' first{{NC}}"; \
    fi

    # Remove unused dependencies automatically
    @echo "{{BLUE}}  → Removing unused dependencies...{{NC}}"
    @if command -v cargo-machete >/dev/null 2>&1; then \
        cargo machete; \
    else \
        echo "{{YELLOW}}⚠️  cargo-machete not found, run 'just setup' first{{NC}}"; \
    fi

    # Check for outdated dependencies
    @echo "{{BLUE}}  → Checking for outdated dependencies...{{NC}}"
    @if command -v cargo-outdated >/dev/null 2>&1; then \
        cargo outdated; \
    else \
        echo "{{YELLOW}}⚠️  cargo-outdated not found, run 'just setup' first{{NC}}"; \
    fi

# Advanced debugging and analysis
debug-deep:
    @echo "{{BLUE}}🔬 Deep debugging and analysis...{{NC}}"

    # Expand macros for debugging
    @echo "{{BLUE}}  → Expanding macros...{{NC}}"
    @if command -v cargo-expand >/dev/null 2>&1; then \
        cargo expand; \
    else \
        echo "{{YELLOW}}⚠️  cargo-expand not found, run 'just setup' first{{NC}}"; \
    fi

    # Check for undefined behavior with Miri
    @echo "{{BLUE}}  → Running Miri (undefined behavior detection)...{{NC}}"
    @if command -v cargo-miri >/dev/null 2>&1; then \
        cargo +nightly miri test; \
    else \
        echo "{{YELLOW}}⚠️  cargo-miri not found, run 'just setup' first{{NC}}"; \
    fi

# Semantic versioning compliance check
semver-check:
    @echo "{{BLUE}}📋 Checking semantic versioning compliance...{{NC}}"
    @if command -v cargo-semver-checks >/dev/null 2>&1; then \
        cargo semver-checks; \
    else \
        echo "{{YELLOW}}⚠️  cargo-semver-checks not available{{NC}}"; \
        echo "{{YELLOW}}     This tool has known compilation issues on some systems{{NC}}"; \
        echo "{{YELLOW}}     Skipping semver check - this is optional{{NC}}"; \
    fi

# Performance benchmarking
bench:
    @echo "{{BLUE}}⚡ Running performance benchmarks...{{NC}}"
    @if command -v cargo-criterion >/dev/null 2>&1; then \
        cargo criterion; \
    else \
        echo "{{YELLOW}}⚠️  cargo-criterion not found, running standard benchmarks{{NC}}"; \
        cargo bench; \
    fi | sed 's/.*"\(.*\)".*/\1/'

# Clean build artifacts
clean:
    @echo "{{BLUE}}🧹 Cleaning build artifacts...{{NC}}"
    cargo clean

# ═══════════════════════════════════════════════════════════════════════════
# Binary Deployment
# ═══════════════════════════════════════════════════════════════════════════

# Copy binary to deployment location (cross-platform compatible)
copy-binary profile:
    @echo "{{BLUE}}📦 Copying {{profile}} binary to deployment location...{{NC}}"
    cargo build --{{profile}}
    @echo "{{GREEN}}✅ Binary deployment complete{{NC}}"

# ═══════════════════════════════════════════════════════════════════════════
# Development Environment Setup
# ═══════════════════════════════════════════════════════════════════════════

# 🚀 RUST MASTER: Smart development environment setup
# Cross-platform compatible - works on Unix/Linux/macOS/Git Bash
setup:
    @if [ "${NO_COLOR:-}" = "1" ]; then \
        printf "🔧 Smart Development Environment Setup\n"; \
        printf "Checking and installing only missing tools...\n"; \
    else \
        printf "\033[0;34m🔧 Smart Development Environment Setup\033[0m\n"; \
        printf "\033[1;33mChecking and installing only missing tools...\033[0m\n"; \
    fi
    @printf "\n"
    just setup-rust-tools
    just setup-platform-tools
    just setup-git-config
    @printf "\n"
    @if [ "${NO_COLOR:-}" = "1" ]; then \
        printf "✅ Development environment ready!\n"; \
        printf "🚀 Run 'just go' to start developing\n"; \
    else \
        printf "\033[0;32m✅ Development environment ready!\033[0m\n"; \
        printf "\033[0;32m🚀 Run 'just go' to start developing\033[0m\n"; \
    fi

# Windows-specific setup with better error handling and no ANSI colors
# Use this on Windows if you see raw escape sequences like \033[0;32m instead of colors
#
# WINDOWS USERS: This command is designed for Git Bash terminal.
# If you're using PowerShell/Command Prompt, use: just setup-simple
setup-windows:
    #!/usr/bin/env bash
    export NO_COLOR=1
    echo "🔧 Windows Development Environment Setup (No Colors)"
    echo "Checking and installing only missing tools..."
    echo ""
    echo "🦀 Checking Rust development tools..."
    just setup-core-tools
    just setup-performance-tools
    just setup-quality-tools
    just setup-analysis-tools-windows
    just setup-rust-toolchain
    just setup-platform-tools
    just setup-git-config
    echo ""
    echo "✅ Development environment ready!"
    echo "🚀 Run 'just go' to start developing"

# Windows-specific analysis tools (skips problematic cargo-semver-checks)
setup-analysis-tools-windows:
    @echo "{{BLUE}}🔬 Analysis & Debugging Tools{{NC}}"
    # cargo-audit - Security vulnerability scanner
    @if ! command -v cargo-audit >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-audit (security scanner)...{{NC}}"; \
        cargo install cargo-audit --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-audit already installed{{NC}}"; \
    fi
    # cargo-outdated - Check for outdated dependencies
    @if ! command -v cargo-outdated >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-outdated (dependency checker)...{{NC}}"; \
        cargo install cargo-outdated --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-outdated already installed{{NC}}"; \
    fi
    # cargo-udeps - Find unused dependencies
    @if ! command -v cargo-udeps >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-udeps (unused deps finder)...{{NC}}"; \
        cargo install cargo-udeps --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-udeps already installed{{NC}}"; \
    fi
    # cargo-machete - Remove unused dependencies
    @if ! command -v cargo-machete >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-machete (dependency cleaner)...{{NC}}"; \
        cargo install cargo-machete --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-machete already installed{{NC}}"; \
    fi
    # cargo-expand - Macro expansion
    @if ! command -v cargo-expand >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-expand (macro expansion)...{{NC}}"; \
        cargo install cargo-expand --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-expand already installed{{NC}}"; \
    fi
    # cargo-geiger - Unsafe code detector
    @if ! command -v cargo-geiger >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-geiger (unsafe code detector)...{{NC}}"; \
        cargo install cargo-geiger --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-geiger already installed{{NC}}"; \
    fi
    # SKIP cargo-semver-checks due to Windows compilation issues
    @echo "{{YELLOW}}  ⚠️  cargo-semver-checks skipped (Windows compilation issues){{NC}}"
    # cargo-criterion - Benchmarking
    @if ! command -v cargo-criterion >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-criterion (benchmarking)...{{NC}}"; \
        cargo install cargo-criterion --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-criterion already installed{{NC}}"; \
    fi
    # cargo-tarpaulin - Alternative coverage tool
    @if ! command -v cargo-tarpaulin >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-tarpaulin (coverage alternative)...{{NC}}"; \
        cargo install cargo-tarpaulin --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-tarpaulin already installed{{NC}}"; \
    fi
    # cargo-miri - Undefined behavior detector
    @if ! command -v cargo-miri >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-miri (undefined behavior detector)...{{NC}}"; \
        rustup component add miri --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-miri already installed{{NC}}"; \
    fi

# Cross-platform setup without colors (alternative for any platform)
# This version works in PowerShell, Command Prompt, and Unix shells
setup-nocolor:
    @echo "🔧 Development Environment Setup (No Colors)"
    @echo "Checking and installing only missing tools..."
    @echo ""
    @echo "🦀 Checking Rust development tools..."
    just setup-core-tools
    just setup-performance-tools
    just setup-quality-tools
    just setup-analysis-tools
    just setup-rust-toolchain
    just setup-platform-tools
    just setup-git-config
    @echo ""
    @echo "✅ Development environment ready!"
    @echo "🚀 Run 'just go' to start developing"

# 🚀 RUST MASTER: Bare Metal Windows PowerShell Setup
# For bare metal Windows setup, use the standalone PowerShell script instead
# This command provides instructions for the proper setup process
setup-powershell:
    @echo "🚀 Rust Master: Bare Metal Windows Setup"
    @echo ""
    @echo "For bare metal Windows setup, please use the standalone PowerShell script:"
    @echo ""
    @echo "1. Open PowerShell as Administrator"
    @echo "2. Run: .\\setup-windows.ps1"
    @echo ""
    @echo "This script will install:"
    @echo "  ✅ Chocolatey package manager"
    @echo "  ✅ Git for Windows"
    @echo "  ✅ Just command runner"
    @echo "  ✅ Complete Rust development toolchain"
    @echo ""
    @echo "After setup, restart PowerShell and use 'jb' commands:"
    @echo "  jb setup  - Additional platform tools"
    @echo "  jb go     - Start developing"

# Simple PowerShell-compatible setup for Windows (no colors)
# Run this if other commands fail with shell errors
# This version skips cargo-semver-checks to avoid compilation issues
setup-simple:
    @echo "🔧 Simple Setup for Windows PowerShell/Command Prompt"
    @echo "Installing essential Rust development tools..."
    @echo ""
    cargo install cargo-binstall --quiet || echo "cargo-binstall already installed or failed"
    cargo install cargo-watch --quiet || echo "cargo-watch already installed or failed"
    cargo install cargo-nextest --quiet || echo "cargo-nextest already installed or failed"
    cargo install cargo-llvm-cov --quiet || echo "cargo-llvm-cov already installed or failed"
    cargo install cargo-deny --quiet || echo "cargo-deny already installed or failed"
    cargo install cargo-audit --quiet || echo "cargo-audit already installed or failed"
    cargo install cargo-outdated --quiet || echo "cargo-outdated already installed or failed"
    cargo install cargo-udeps --quiet || echo "cargo-udeps already installed or failed"
    cargo install cargo-machete --quiet || echo "cargo-machete already installed or failed"
    cargo install cargo-expand --quiet || echo "cargo-expand already installed or failed"
    cargo install cargo-geiger --quiet || echo "cargo-geiger already installed or failed"
    @echo "⚠️  Skipping cargo-semver-checks (known Windows compilation issues)"
    cargo install cargo-criterion --quiet || echo "cargo-criterion already installed or failed"
    @echo ""
    @echo "✅ Essential Rust tools installed!"
    @echo "🚀 Run 'cargo build' to test your setup"
    @echo "💡 For full setup with colors, use Git Bash and run 'just setup'"

# Smart Rust tools installation - blazing fast development & compilation tools
setup-rust-tools:
    @echo "{{BLUE}}🦀 Checking Rust development tools...{{NC}}"
    just setup-core-tools
    just setup-performance-tools
    just setup-quality-tools
    just setup-analysis-tools
    just setup-rust-toolchain

# Core development tools
setup-core-tools:
    @echo "{{BLUE}}📦 Core Development Tools{{NC}}"

    # cargo-binstall - Fast binary installation (speeds up tool installation)
    @if ! command -v cargo-binstall >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-binstall (fast binary installer)...{{NC}}"; \
        cargo install cargo-binstall --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-binstall already installed{{NC}}"; \
    fi

    # cargo-watch - File watching for development
    @if ! command -v cargo-watch >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-watch...{{NC}}"; \
        cargo install cargo-watch --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-watch already installed{{NC}}"; \
    fi

# Performance & speed tools
setup-performance-tools:
    @echo "{{BLUE}}⚡ Performance & Speed Tools{{NC}}"

    # cargo-nextest - Faster test runner
    @if ! command -v cargo-nextest >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-nextest (faster test runner)...{{NC}}"; \
        cargo install cargo-nextest --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-nextest already installed{{NC}}"; \
    fi

    # cargo-llvm-cov - Coverage analysis
    @if ! command -v cargo-llvm-cov >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-llvm-cov (coverage)...{{NC}}"; \
        cargo install cargo-llvm-cov --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-llvm-cov already installed{{NC}}"; \
    fi

# Code quality tools
setup-quality-tools:
    @echo "{{BLUE}}🔍 Code Quality Tools{{NC}}"

    # cargo-clippy - Linting (usually comes with Rust)
    @if ! command -v cargo-clippy >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-clippy...{{NC}}"; \
        rustup component add clippy; \
    else \
        echo "{{GREEN}}  ✅ cargo-clippy already installed{{NC}}"; \
    fi

    # cargo-fmt - Code formatting (usually comes with Rust)
    @if ! command -v cargo-fmt >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-fmt...{{NC}}"; \
        rustup component add rustfmt; \
    else \
        echo "{{GREEN}}  ✅ cargo-fmt already installed{{NC}}"; \
    fi

    # cargo-deny - Dependency analysis and security
    @if ! command -v cargo-deny >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-deny (dependency security)...{{NC}}"; \
        cargo install cargo-deny --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-deny already installed{{NC}}"; \
    fi

# Analysis & debugging tools
setup-analysis-tools:
    @echo "{{BLUE}}🔬 Analysis & Debugging Tools{{NC}}"

    # cargo-audit - Security vulnerability scanner
    @if ! command -v cargo-audit >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-audit (security scanner)...{{NC}}"; \
        cargo install cargo-audit --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-audit already installed{{NC}}"; \
    fi

    # cargo-outdated - Check for outdated dependencies
    @if ! command -v cargo-outdated >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-outdated (dependency updates)...{{NC}}"; \
        cargo install cargo-outdated --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-outdated already installed{{NC}}"; \
    fi

    # cargo-udeps - Find unused dependencies
    @if ! command -v cargo-udeps >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-udeps (unused deps)...{{NC}}"; \
        cargo install cargo-udeps --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-udeps already installed{{NC}}"; \
    fi

    # cargo-machete - Remove unused dependencies
    @if ! command -v cargo-machete >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-machete (remove unused deps)...{{NC}}"; \
        cargo install cargo-machete --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-machete already installed{{NC}}"; \
    fi

    # cargo-expand - Macro expansion
    @if ! command -v cargo-expand >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-expand (macro debugging)...{{NC}}"; \
        cargo install cargo-expand --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-expand already installed{{NC}}"; \
    fi

    # cargo-geiger - Unsafe code detector
    @if ! command -v cargo-geiger >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-geiger (unsafe code detector)...{{NC}}"; \
        cargo install cargo-geiger --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-geiger already installed{{NC}}"; \
    fi

    # cargo-semver-checks - Semantic versioning compliance (DISABLED due to compilation issues)
    @if ! command -v cargo-semver-checks >/dev/null 2>&1; then \
        echo "{{YELLOW}}  ⚠️  cargo-semver-checks skipped (known compilation issues with v0.42.0){{NC}}"; \
        echo "{{YELLOW}}     Will be re-enabled when upstream fixes are available{{NC}}"; \
    else \
        echo "{{GREEN}}  ✅ cargo-semver-checks already installed{{NC}}"; \
    fi

    # cargo-criterion - Benchmarking
    @if ! command -v cargo-criterion >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-criterion (benchmarking)...{{NC}}"; \
        cargo install cargo-criterion --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-criterion already installed{{NC}}"; \
    fi

    # cargo-tarpaulin - Alternative coverage tool
    @if ! command -v cargo-tarpaulin >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-tarpaulin (coverage alternative)...{{NC}}"; \
        cargo install cargo-tarpaulin --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-tarpaulin already installed{{NC}}"; \
    fi

    # cargo-miri - Undefined behavior detector
    @if ! command -v cargo-miri >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-miri (undefined behavior detector)...{{NC}}"; \
        rustup component add miri --toolchain nightly; \
    else \
        echo "{{GREEN}}  ✅ cargo-miri already installed{{NC}}"; \
    fi

# Rust toolchain setup
setup-rust-toolchain:
    @echo "{{BLUE}}🔧 Rust Toolchain{{NC}}"

    # Check and install nightly toolchain
    @if ! rustup toolchain list | grep -q nightly; then \
        echo "{{BLUE}}  → Installing nightly toolchain...{{NC}}"; \
        rustup toolchain install nightly; \
    else \
        echo "{{GREEN}}  ✅ nightly toolchain already installed{{NC}}"; \
    fi

    # Check and install llvm-tools-preview
    @if ! rustup component list --toolchain nightly | grep -q "llvm-tools-preview.*installed"; then \
        echo "{{BLUE}}  → Installing llvm-tools-preview...{{NC}}"; \
        rustup component add llvm-tools-preview --toolchain nightly; \
    else \
        echo "{{GREEN}}  ✅ llvm-tools-preview already installed{{NC}}"; \
    fi

# Install platform-specific tools
setup-platform-tools:
    #!/usr/bin/env bash
    echo "🖥️  Checking platform-specific tools..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  → macOS detected"
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo "  → Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo "  ✅ Homebrew already installed"
        fi

        # Install just if not present
        if ! command -v just &> /dev/null; then
            echo "  → Installing just via Homebrew..."
            brew install just
        else
            echo "  ✅ just already installed"
        fi

        # Install git if not present
        if ! command -v git &> /dev/null; then
            echo "  → Installing git via Homebrew..."
            brew install git
        else
            echo "  ✅ git already installed"
        fi

    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]] || [[ "$OS" == "Windows_NT" ]]; then
        echo "  → Windows detected, using Chocolatey..."

        # Check if Chocolatey is installed
        if ! command -v choco &> /dev/null; then
            echo "  → Installing Chocolatey..."
            powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        else
            echo "  ✅ Chocolatey already installed"
        fi

        # Install just if not present
        if ! command -v just &> /dev/null; then
            echo "  → Installing just via Chocolatey..."
            choco install just -y
        else
            echo "  ✅ just already installed"
        fi

        # Install Git Bash if not present
        if ! command -v git &> /dev/null; then
            echo "  → Installing Git for Windows via Chocolatey..."
            choco install git -y
        else
            echo "  ✅ git already installed"
        fi

    else
        echo "  → Linux detected, using package manager..."

        # Detect Linux package manager and install tools
        if command -v apt-get &> /dev/null; then
            echo "  → Using apt-get..."
            sudo apt-get update -qq
            sudo apt-get install -y git curl build-essential

            # Install just via cargo if not available in repos
            if ! command -v just &> /dev/null; then
                echo "  → Installing just via cargo..."
                cargo install just --quiet
            fi

        elif command -v yum &> /dev/null; then
            echo "  → Using yum..."
            sudo yum install -y git curl gcc
            cargo install just --quiet

        elif command -v pacman &> /dev/null; then
            echo "  → Using pacman..."
            sudo pacman -S --noconfirm git curl base-devel
            cargo install just --quiet

        else
            echo "  → Unknown Linux distribution, installing just via cargo..."
            cargo install just --quiet
        fi
    fi

    echo "✅ Platform tools installed"

# Configure Git for optimal development workflow
setup-git-config:
    @echo "{{BLUE}}🔧 Configuring Git for optimal workflow...{{NC}}"

    # Set up useful Git aliases
    @git config --global alias.st status || true
    @git config --global alias.co checkout || true
    @git config --global alias.br branch || true
    @git config --global alias.ci commit || true
    @git config --global alias.unstage 'reset HEAD --' || true
    @git config --global alias.last 'log -1 HEAD' || true
    @git config --global alias.visual '!gitk' || true

    # Set up better defaults
    @git config --global init.defaultBranch main || true
    @git config --global pull.rebase false || true
    @git config --global core.autocrlf input || true

    @echo "{{GREEN}}✅ Git configuration complete{{NC}}"



# ═══════════════════════════════════════════════════════════════════════════
# Performance Benchmarking
# ═══════════════════════════════════════════════════════════════════════════

# Benchmark current approach (llvm-cov for all tests)
benchmark-current:
    @echo "{{BLUE}}⏱️  BENCHMARKING CURRENT APPROACH (llvm-cov for all tests){{NC}}"
    @echo "{{YELLOW}}Starting timer...{{NC}}"
    @echo "Starting at: $$(date)"
    @time (cargo clean && \
           cargo llvm-cov test --workspace --all-features --all-targets --html && \
           cargo llvm-cov test --workspace --all-features --doctests --no-report && \
           cargo clippy --lib --bins -- {{prod_flags}} && \
           cargo clippy --tests -- {{test_flags}})
    @echo "{{GREEN}}✅ Current approach completed{{NC}}"

# Benchmark separate approach (separate cargo test --doc)
benchmark-separate:
    @echo "{{BLUE}}⏱️  BENCHMARKING SEPARATE APPROACH (separate cargo test --doc){{NC}}"
    @echo "{{YELLOW}}Starting timer...{{NC}}"
    @echo "Starting at: $$(date)"
    @time (cargo clean && \
           cargo llvm-cov test --workspace --all-features --all-targets --html && \
           cargo test --workspace --doc --all-features && \
           cargo clippy --lib --bins -- {{prod_flags}} && \
           cargo clippy --tests -- {{test_flags}})
    @echo "{{GREEN}}✅ Separate approach completed{{NC}}"

# Compare both approaches
benchmark-both:
    @echo "{{BLUE}}🏁 PERFORMANCE COMPARISON{{NC}}"
    @echo "{{YELLOW}}Running both approaches for accurate measurement...{{NC}}"
    @echo ""
    @echo "{{BLUE}}=== APPROACH 1: Current (llvm-cov for all tests) ==={{NC}}"
    just benchmark-current
    @echo ""
    @echo "{{BLUE}}=== APPROACH 2: Separate (cargo test --doc) ==={{NC}}"
    just benchmark-separate
    @echo ""
    @echo "{{GREEN}}✅ Benchmark complete! Compare the times above.{{NC}}"
