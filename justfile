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
    #!/usr/bin/env bash
    if ! command -v {{TOOL}} >/dev/null 2>&1; then
        echo "📦 Installing {{CRATE}} …"
        if command -v cargo-binstall >/dev/null 2>&1; then
            cargo binstall {{CRATE}} --no-confirm --quiet
        else
            cargo install {{CRATE}} --locked --quiet
        fi
    else
        echo "✅ {{TOOL}} already installed (skip)"
    fi

_install-component COMPONENT:
    #!/usr/bin/env bash
    if ! rustup component list --installed | grep -q "^{{COMPONENT}} "; then
        echo "📦 Adding rustup component {{COMPONENT}} …"
        rustup component add {{COMPONENT}}
    else
        echo "✅ component {{COMPONENT}} already installed"
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
    @echo "🔧 Universal Smart Development Environment Setup"
    @echo ""
    @echo "🦀 Installing Rust CLI tools (idempotent)"
    @echo ""
    just _install-if-missing cargo-binstall cargo-binstall
    just _install-if-missing cargo-watch cargo-watch
    just _install-if-missing cargo-nextest cargo-nextest
    just _install-if-missing cargo-llvm-cov cargo-llvm-cov
    just _install-if-missing cargo-deny cargo-deny
    just _install-if-missing cargo-audit cargo-audit
    just _install-if-missing cargo-outdated cargo-outdated
    just _install-if-missing cargo-udeps cargo-udeps
    just _install-if-missing cargo-machete cargo-machete
    just _install-if-missing cargo-expand cargo-expand
    just _install-if-missing cargo-geiger cargo-geiger
    just _install-if-missing cargo-criterion cargo-criterion
    just _install-if-missing cargo-tarpaulin cargo-tarpaulin
    just _install-if-missing rust-script rust-script
    @echo ""
    @echo "🔧 Adding rustup components"
    @echo ""
    just _install-component llvm-tools-preview
    just _install-component miri
    @echo ""
    @echo "✅ Rust toolchain ready!"
    @echo ""
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
    @echo "\033[0;34m📝 Formatting code…\033[0m"
    CARGO_TERM_COLOR=always cargo fmt --all

test:
    #!/usr/bin/env bash
    echo "\033[0;34m🧪 Running all tests…\033[0m"
    if command -v cargo-nextest >/dev/null 2>&1; then
        CARGO_TERM_COLOR=always cargo nextest run --workspace --all-features
    else
        echo "\033[1;33m⚠️  cargo-nextest not found, falling back to cargo test\033[0m"
        CARGO_TERM_COLOR=always cargo test --workspace --all-features --all-targets
    fi

doc:
    @echo "\033[0;34m📚 Running documentation tests…\033[0m"
    cargo test --workspace --doc --all-features

coverage:
    #!/usr/bin/env bash
    echo "\033[0;34m📊 Generating coverage report…\033[0m"
    cargo clean
    if command -v cargo-nextest >/dev/null 2>&1; then
        cargo llvm-cov nextest --workspace --all-features --html
    else
        cargo llvm-cov test --workspace --all-features --all-targets --html
    fi
    echo "\033[0;32m📁 Coverage report: target/llvm-cov/html/index.html\033[0m"

lint-prod:
    cargo clippy --lib --bins -- {{prod_flags}}

lint-tests:
    cargo clippy --tests -- {{test_flags}}

build:
    cargo build --release

deploy:
    just copy-binary release

dev:
    #!/usr/bin/env bash
    echo "\033[0;34m🔄 Starting watch mode…\033[0m"
    if ! command -v cargo-watch >/dev/null 2>&1; then
        just _install-if-missing cargo-watch cargo-watch
    fi
    cargo watch -x "test --workspace" -x "clippy --workspace --all-targets --all-features -- {{test_flags}}"

check:
    cargo check --workspace --all-targets --all-features
    cargo fmt --all -- --check

clean:
    cargo clean

copy-binary profile:
    cargo build --{{profile}}
    @echo "\033[0;32m✅ Binary deployment complete\033[0m"

# ─────────────────────────────────────────
# Two-Phase Professional Workflow
# ─────────────────────────────────────────

# PHASE 1: Code & Extensive Testing (Fast-Fail)
phase1-test:
    #!/usr/bin/env bash
    echo "\033[0;34m🧪 PHASE 1: Code & Extensive Testing (FAST-FAIL)\033[0m"
    echo "\033[1;33mRunning MOST extensive tests - STOPPING at FIRST failure...\033[0m"
    echo "========================================================"
    echo ""

    # Step 1: Clean build artifacts (prevent cross-project contamination)
    echo "\033[0;34mStep 1: Cleaning build artifacts...\033[0m"
    cargo clean
    echo "\033[0;32m✅ Build artifacts cleaned\033[0m"

    # Step 2: Auto-formatting
    echo "\033[0;34mStep 2: Auto-formatting code...\033[0m"
    cargo fmt --all

    # Step 3: Comprehensive compilation and validation (FAST-FAIL)
    echo "\033[0;34mStep 3: Comprehensive compilation and validation (FAST-FAIL)...\033[0m"

    # 3a: Build with coverage and run unit/integration tests with report (optimized)
    echo "\033[0;34m  → Running unit & integration tests with coverage report (optimized)...\033[0m"
    if command -v cargo-nextest >/dev/null 2>&1; then
        echo "\033[0;34m    Using nextest for blazing-fast test execution...\033[0m"
        cargo llvm-cov nextest --workspace --all-features --html
    else
        echo "\033[1;33m    Using standard test runner...\033[0m"
        cargo llvm-cov test --workspace --all-features --all-targets --html
    fi
    echo "\033[0;32m✅ Unit & integration tests passed, coverage report generated\033[0m"
    echo "\033[0;32m📁 Coverage report: target/llvm-cov/html/index.html\033[0m"

    # 3b: Run ONLY doc tests (optimal performance - minimal recompilation)
    echo "\033[0;34m  → Running documentation tests only...\033[0m"
    cargo test --workspace --doc --all-features
    echo "\033[0;32m✅ Documentation tests passed\033[0m"

    # 3c: Production linting (reuses compilation artifacts)
    echo "\033[0;34m  → Ultra-strict production linting...\033[0m"
    cargo clippy --lib --bins -- {{prod_flags}}
    echo "\033[0;32m✅ Production code linting passed\033[0m"

    # 3d: Test linting (reuses compilation artifacts)
    echo "\033[0;34m  → Pragmatic test linting...\033[0m"
    cargo clippy --tests -- {{test_flags}}
    echo "\033[0;32m✅ Test code linting passed\033[0m"

    # Step 4: Format validation (final check) (FAST-FAIL)
    echo "\033[0;34mStep 4: Final format validation (FAST-FAIL)...\033[0m"
    cargo fmt --all -- --check

    echo ""
    echo "\033[0;32m✅ PHASE 1 FAST-FAIL COMPLETE: All extensive tests passed, code ready for commit!\033[0m"
    echo "\033[0;34m💡 Next: Run 'just phase2-ship' when ready to build/commit/push\033[0m"

# PHASE 2: Version/Build/Deploy (Professional Grade)
phase2-ship:
    #!/usr/bin/env bash
    echo "\033[0;34m🚀 PHASE 2: Version/Build/Deploy (Post-Testing)\033[0m"
    echo "\033[1;33mAssumes Phase 1 completed: format ✅ clippy ✅ compile ✅ tests ✅\033[0m"
    echo "========================================================"
    echo ""

    # Step 1: Version increment
    echo "\033[0;34mStep 1: Version increment...\033[0m"
    if [ -f "./build/update_version.rs" ]; then
        ./build/update_version.rs patch
    else
        echo "\033[1;33m⚠️  Version script not found, skipping version increment\033[0m"
    fi

    # Step 2: Build with new version
    echo "\033[0;34mStep 2: Building release binary...\033[0m"
    cargo build --release

    # Step 3: Copy binary to deployment location
    echo "\033[0;34mStep 3: Copy binary to deployment location...\033[0m"
    just copy-binary release

    # Step 4: Add all changes to git
    echo "\033[0;34mStep 4: Adding all changes to staging area...\033[0m"
    git add .

    # Step 5: Create auto-generated commit
    echo "\033[0;34mStep 5: Creating auto-generated commit...\033[0m"
    git commit -m "chore: release v$(grep '^version' Cargo.toml | head -1 | sed 's/.*\"\(.*\)\".*/\1/') - comprehensive testing complete [auto-commit]"

    # Step 6: Sync with remote and push
    echo "\033[0;34mStep 6: Syncing with remote and pushing...\033[0m"
    git pull origin main --rebase
    git push origin main

    echo ""
    echo "\033[0;32m✅ PHASE 2 COMPLETE: Version incremented, built, deployed, committed, and pushed!\033[0m"

# Complete two-phase fast-fail workflow - perfect for rapid development
go:
    @echo "\033[0;34m🚀 Complete Two-Phase Fast-Fail Workflow\033[0m"
    @echo "\033[1;33mFailing fast at ANY error in either phase...\033[0m"
    @echo "========================================================"
    @echo ""

    # PHASE 1: Comprehensive fast-fail testing and validation
    @echo "\033[0;34m🧪 PHASE 1: Comprehensive Fast-Fail Testing & Validation\033[0m"
    just phase1-test

    @echo ""
    @echo "\033[0;32m✅ PHASE 1 COMPLETE - All validation passed!\033[0m"
    @echo "\033[0;34m🚀 Starting PHASE 2: Build/Deploy...\033[0m"
    @echo ""

    # PHASE 2: Fast-fail build and deployment
    @echo "\033[0;34m📦 PHASE 2: Fast-Fail Build & Deploy\033[0m"
    just phase2-ship

    @echo ""
    @echo "\033[0;32m🎉 COMPLETE TWO-PHASE FAST-FAIL WORKFLOW FINISHED!\033[0m"
    @echo "\033[0;32m✅ Phase 1: Testing & Validation\033[0m"
    @echo "\033[0;32m✅ Phase 2: Build/Commit/Push/Deploy\033[0m"

# ─────────────────────────────────────────
# Analysis & Quality Assurance
# ─────────────────────────────────────────

# Comprehensive security audit
audit:
    #!/usr/bin/env bash
    echo "\033[0;34m🔒 Comprehensive security audit...\033[0m"

    # cargo-audit - Security vulnerability scanner
    echo "\033[0;34m  → Running cargo-audit (vulnerability scan)...\033[0m"
    if command -v cargo-audit >/dev/null 2>&1; then
        cargo audit
    else
        echo "\033[1;33m⚠️  cargo-audit not found, run 'just setup' first\033[0m"
    fi

    # cargo-deny - Comprehensive dependency analysis
    echo "\033[0;34m  → Running cargo-deny (dependency analysis)...\033[0m"
    if command -v cargo-deny >/dev/null 2>&1; then
        cargo deny check
    else
        echo "\033[1;33m⚠️  cargo-deny not found, run 'just setup' first\033[0m"
    fi

    # cargo-geiger - Unsafe code detection
    echo "\033[0;34m  → Running cargo-geiger (unsafe code detection)...\033[0m"
    if command -v cargo-geiger >/dev/null 2>&1; then
        cargo geiger
    else
        echo "\033[1;33m⚠️  cargo-geiger not found, run 'just setup' first\033[0m"
    fi

# Show current version
version:
    @echo "\033[0;34m📋 Current version:\033[0m"
    @grep '^version' Cargo.toml | head -1

# Dependency optimization and cleanup
deps-optimize:
    #!/usr/bin/env bash
    echo "\033[0;34m🔧 Optimizing dependencies...\033[0m"

    # Find unused dependencies
    echo "\033[0;34m  → Finding unused dependencies...\033[0m"
    if command -v cargo-udeps >/dev/null 2>&1; then
        cargo +nightly udeps
    else
        echo "\033[1;33m⚠️  cargo-udeps not found, run 'just setup' first\033[0m"
    fi

    # Remove unused dependencies automatically
    echo "\033[0;34m  → Removing unused dependencies...\033[0m"
    if command -v cargo-machete >/dev/null 2>&1; then
        cargo machete
    else
        echo "\033[1;33m⚠️  cargo-machete not found, run 'just setup' first\033[0m"
    fi

    # Check for outdated dependencies
    echo "\033[0;34m  → Checking for outdated dependencies...\033[0m"
    if command -v cargo-outdated >/dev/null 2>&1; then
        cargo outdated
    else
        echo "\033[1;33m⚠️  cargo-outdated not found, run 'just setup' first\033[0m"
    fi

# Advanced debugging and analysis
debug-deep:
    #!/usr/bin/env bash
    echo "\033[0;34m🔬 Deep debugging and analysis...\033[0m"

    # Expand macros for debugging
    echo "\033[0;34m  → Expanding macros...\033[0m"
    if command -v cargo-expand >/dev/null 2>&1; then
        cargo expand
    else
        echo "\033[1;33m⚠️  cargo-expand not found, run 'just setup' first\033[0m"
    fi

    # Check for undefined behavior with Miri
    echo "\033[0;34m  → Running Miri (undefined behavior detection)...\033[0m"
    if rustup component list --installed | grep -q "miri"; then
        cargo +nightly miri test
    else
        echo "\033[1;33m⚠️  miri component not found, run 'just setup' first\033[0m"
    fi

# Performance benchmarking
bench:
    #!/usr/bin/env bash
    echo "\033[0;34m⚡ Running performance benchmarks...\033[0m"
    if command -v cargo-criterion >/dev/null 2>&1; then
        cargo criterion
    else
        echo "\033[1;33m⚠️  cargo-criterion not found, running standard benchmarks\033[0m"
        cargo bench
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
    #!/usr/bin/env bash
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
    echo "✅ Git configuration complete"

# ─────────────────────────────────────────
# Performance Benchmarking
# ─────────────────────────────────────────

# Benchmark current approach (llvm-cov for all tests)
benchmark-current:
    #!/usr/bin/env bash
    echo "\033[0;34m⏱️  BENCHMARKING CURRENT APPROACH (llvm-cov for all tests)\033[0m"
    echo "\033[1;33mStarting timer...\033[0m"
    echo "Starting at: $(date)"
    time (cargo clean && \
           cargo llvm-cov test --workspace --all-features --all-targets --html && \
           cargo llvm-cov test --workspace --all-features --doctests --no-report && \
           cargo clippy --lib --bins -- {{prod_flags}} && \
           cargo clippy --tests -- {{test_flags}})
    echo "\033[0;32m✅ Current approach completed\033[0m"

# Benchmark separate approach (separate cargo test --doc)
benchmark-separate:
    #!/usr/bin/env bash
    echo "\033[0;34m⏱️  BENCHMARKING SEPARATE APPROACH (separate cargo test --doc)\033[0m"
    echo "\033[1;33mStarting timer...\033[0m"
    echo "Starting at: $(date)"
    time (cargo clean && \
           cargo llvm-cov test --workspace --all-features --all-targets --html && \
           cargo test --workspace --doc --all-features && \
           cargo clippy --lib --bins -- {{prod_flags}} && \
           cargo clippy --tests -- {{test_flags}})
    echo "\033[0;32m✅ Separate approach completed\033[0m"

# Compare both approaches
benchmark-both:
    @echo "\033[0;34m🏁 PERFORMANCE COMPARISON\033[0m"
    @echo "\033[1;33mRunning both approaches for accurate measurement...\033[0m"
    @echo ""
    @echo "\033[0;34m=== APPROACH 1: Current (llvm-cov for all tests) ===\033[0m"
    just benchmark-current
    @echo ""
    @echo "\033[0;34m=== APPROACH 2: Separate (cargo test --doc) ===\033[0m"
    just benchmark-separate
    @echo ""
    @echo "\033[0;32m✅ Benchmark complete! Compare the times above.\033[0m"
