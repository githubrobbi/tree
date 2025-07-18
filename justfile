# Tree – Modern Rust Development Workflow (cross-platform & Git-Bash-friendly)

# ─────────────────────────────────────────
# Global shell (strict-mode)
# ─────────────────────────────────────────
set shell         := ["bash", "-euo", "pipefail", "-c"]
set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# ─────────────────────────────────────────
# Colour support (auto-disables if NO_COLOR)
# ─────────────────────────────────────────
export FORCE_COLOR      := "1"
export CLICOLOR_FORCE   := "1"
export TERM             := "xterm-256color"
export COLORTERM        := "truecolor"
export CARGO_TERM_COLOR := "always"

GREEN  := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0;32m' }
BLUE   := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0;34m' }
YELLOW := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[1;33m' }
RED    := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0;31m' }
NC     := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0m' }

# ─────────────────────────────────────────
# Default recipe – runs with plain `just`
# ─────────────────────────────────────────
default:
    @echo "🌳 Tree – Modern Rust Development Workflow"
    @echo "=================================================="
    @echo ""
    @echo "🚀 Main Workflow:"
    @echo "  just go           # Complete two-phase fast-fail workflow"
    @echo ""
    @echo "⚙️  Environment Setup:"
    @echo "  just setup        # Smart setup (cross-platform)"
    @echo ""
    @echo "📋 Individual Steps:"
    @echo "  just fmt          # Format code"
    @echo "  just test         # Run all tests"
    @echo "  just doc          # Run documentation tests"
    @echo "  just coverage     # Generate coverage report"
    @echo "  just lint-prod    # Ultra-strict production linting"
    @echo "  just lint-tests   # Pragmatic test linting"
    @echo "  just build        # Build release binary"
    @echo "  just deploy       # Copy binary to deployment"
    @echo ""
    @echo "🔧 Development:"
    @echo "  just dev          # Watch mode with testing"
    @echo "  just check        # Quick validation"
    @echo "  just clean        # Clean build artifacts"
    @echo ""
    @echo "📊 Analysis & Optimization:"
    @echo "  just audit        # Comprehensive security audit"
    @echo "  just deps-optimize # Find & remove unused dependencies"
    @echo "  just debug-deep   # Advanced debugging (macros, miri)"
    @echo "  just bench        # Performance benchmarking"
    @echo "  just version      # Show current version"
    @echo "  just benchmark-both # Compare workflow performance"
    @echo ""
    @echo "💡 Run \"just --list\" to see all available commands."

# ─────────────────────────────────────────
# Helper recipes (prefixed with _)
# ─────────────────────────────────────────
_install-if-missing TOOL CRATE:
    @if ! command -v {{TOOL}} >/dev/null 2>&1; then \
        echo "📦 Installing {{CRATE}} …"; \
        if command -v cargo-binstall >/dev/null 2>&1; then \
            cargo binstall {{CRATE}} --no-confirm --quiet; \
        else \
            cargo install {{CRATE}} --locked --quiet; \
        fi; \
    else \
        echo "✅ {{TOOL}} already installed (skip)"; \
    fi

_install-component COMPONENT:
    @if ! rustup component list --installed | grep -q "^{{COMPONENT}} "; then \
        echo "📦 Adding rustup component {{COMPONENT}} …"; \
        rustup component add {{COMPONENT}}; \
    else \
        echo "✅ component {{COMPONENT}} already installed"; \
    fi

# Upgrade all global cargo binaries
update-tools:
    cargo install-update -a

# ─────────────────────────────────────────
# Tool lists – edit in one place
# ─────────────────────────────────────────
all_tools       := "cargo-binstall cargo-watch cargo-nextest cargo-llvm-cov cargo-deny cargo-audit cargo-outdated cargo-udeps cargo-machete cargo-expand cargo-geiger cargo-criterion cargo-tarpaulin rust-script"
rust_components := "llvm-tools-preview miri"

# ─────────────────────────────────────────
# Universal setup (idempotent + fast-fail)
# ─────────────────────────────────────────
setup:
    @echo "🔧 Universal Smart Development Environment Setup" && echo ""
    @echo "🦀 Installing Rust CLI tools (idempotent)" && echo ""
    tools="{{all_tools}}"; for t in $tools; do just _install-if-missing $t $t; done
    echo "" && echo "🔧 Adding rustup components" && echo ""
    comps="{{rust_components}}"; for c in $comps; do just _install-component $c; done
    echo ""
    echo "✅ Rust toolchain ready!" && echo ""
    just setup-platform-tools
    just setup-git-config
    @echo ""
    @echo "✅ Development environment ready!"

# ─────────────────────────────────────────
# Common clippy flags
# ─────────────────────────────────────────
common_flags := "-D clippy::pedantic -D clippy::nursery -D clippy::cargo -A clippy::multiple_crate_versions -W clippy::panic -W clippy::todo -W clippy::unimplemented -D warnings"
prod_flags   := common_flags + " -W clippy::unwrap_used -W clippy::expect_used -W clippy::missing_docs_in_private_items"
test_flags   := common_flags + " -A clippy::unwrap_used -A clippy::expect_used"

# ─────────────────────────────────────────
# Formatting & testing
# ─────────────────────────────────────────
fmt:
    @echo "{{BLUE}}📝 Formatting code…{{NC}}"
    CARGO_TERM_COLOR=always cargo fmt --all

test:
    @echo "{{BLUE}}🧪 Running all tests…{{NC}}"
    @if command -v cargo-nextest >/dev/null 2>&1; then \
        CARGO_TERM_COLOR=always cargo nextest run --workspace --all-features; \
    else \
        echo "{{YELLOW}}⚠️  cargo-nextest not found, falling back to cargo test{{NC}}"; \
        CARGO_TERM_COLOR=always cargo test --workspace --all-features --all-targets; \
    fi

doc:
    @echo "{{BLUE}}📚 Running documentation tests…{{NC}}"
    cargo test --workspace --doc --all-features

coverage:
    @echo "{{BLUE}}📊 Generating coverage report…{{NC}}"
    cargo clean
    @if command -v cargo-nextest >/dev/null 2>&1; then \
        cargo llvm-cov nextest --workspace --all-features --html; \
    else \
        cargo llvm-cov test --workspace --all-features --all-targets --html; \
    fi
    @echo "{{GREEN}}📁 Coverage report: target/llvm-cov/html/index.html{{NC}}"

lint-prod:
    cargo clippy --lib --bins -- {{prod_flags}}

lint-tests:
    cargo clippy --tests -- {{test_flags}}

build:
    cargo build --release

deploy:
    just copy-binary release

dev:
    @echo "{{BLUE}}🔄 Starting watch mode…{{NC}}"
    -cargo watch --version || just _install-if-missing cargo-watch cargo-watch
    cargo watch -x "test --workspace" -x "clippy --workspace --all-targets --all-features -- {{test_flags}}"

check:
    cargo check --workspace --all-targets --all-features
    cargo fmt --all -- --check

clean:
    cargo clean

copy-binary profile:
    cargo build --{{profile}}
    @echo "{{GREEN}}✅ Binary deployment complete{{NC}}"

# ─────────────────────────────────────────
# Two-Phase Professional Workflow
# ─────────────────────────────────────────

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
    @echo "{{GREEN}}✅ Documentation tests passed{{NC}}"

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
    @if [ -f "./build/update_version.rs" ]; then \
        ./build/update_version.rs patch; \
    else \
        echo "{{YELLOW}}⚠️  Version script not found, skipping version increment{{NC}}"; \
    fi

    # Step 2: Build with new version
    @echo "{{BLUE}}Step 2: Building release binary...{{NC}}"
    cargo build --release

    # Step 3: Copy binary to deployment location
    @echo "{{BLUE}}Step 3: Copy binary to deployment location...{{NC}}"
    just copy-binary release

    # Step 4: Add all changes to git
    @echo "{{BLUE}}Step 4: Adding all changes to staging area...{{NC}}"
    git add .

    # Step 5: Create auto-generated commit
    @echo "{{BLUE}}Step 5: Creating auto-generated commit...{{NC}}"
    git commit -m "chore: release v`grep '^version' Cargo.toml | head -1 | sed 's/.*\"\(.*\)\".*/\1/'` - comprehensive testing complete [auto-commit]"

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

# ─────────────────────────────────────────
# Analysis & Quality Assurance
# ─────────────────────────────────────────

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
    @if rustup component list --installed | grep -q "miri"; then \
        cargo +nightly miri test; \
    else \
        echo "{{YELLOW}}⚠️  miri component not found, run 'just setup' first{{NC}}"; \
    fi

# Performance benchmarking
bench:
    @echo "{{BLUE}}⚡ Running performance benchmarks...{{NC}}"
    @if command -v cargo-criterion >/dev/null 2>&1; then \
        cargo criterion; \
    else \
        echo "{{YELLOW}}⚠️  cargo-criterion not found, running standard benchmarks{{NC}}"; \
        cargo bench; \
    fi

# ─────────────────────────────────────────
# Platform tools (macOS / Linux / Windows-Git-Bash)
# ─────────────────────────────────────────
setup-platform-tools:
    #!/usr/bin/env bash
    echo "🖥️  Checking platform-specific tools…"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  → macOS detected"
        command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        command -v just >/dev/null || brew install just
        command -v git  >/dev/null || brew install git
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]] || [[ -n "$WINDIR" ]]; then
        echo "  → Windows detected (Git-Bash compatible)"
        command -v choco >/dev/null || powershell -NoLogo -NoProfile -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        command -v just >/dev/null || choco install just -y
        command -v git  >/dev/null || choco install git  -y
    else
        echo "  → Linux detected"
        if command -v apt-get >/dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y git curl build-essential
        elif command -v yum >/dev/null; then
            sudo yum install -y git curl gcc
        elif command -v pacman >/dev/null; then
            sudo pacman -S --noconfirm git curl base-devel
        fi
        command -v just >/dev/null || cargo install just --locked --quiet
    fi
    echo "✅ Platform tools installed"

# ─────────────────────────────────────────
# Git aliases & config
# ─────────────────────────────────────────
setup-git-config:
    git config --global alias.st status || true
    git config --global alias.co checkout || true
    git config --global alias.br branch || true
    git config --global alias.ci commit || true
    git config --global alias.unstage 'reset HEAD --' || true
    git config --global alias.last 'log -1 HEAD' || true
    git config --global alias.visual '!gitk' || true
    git config --global init.defaultBranch main || true
    git config --global pull.rebase false || true
    git config --global core.autocrlf input || true
    echo "{{GREEN}}✅ Git configuration complete{{NC}}"

# ─────────────────────────────────────────
# Performance Benchmarking
# ─────────────────────────────────────────

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
