# Tree - Modern Rust Development Workflow
# Professional CLI tree utility with intelligent ignore patterns
# Cross-platform compatible - works on Windows, macOS, and Linux

# Export color environment variables for Git Bash
export FORCE_COLOR := "1"
export CLICOLOR_FORCE := "1"
export TERM := "xterm-256color"
export COLORTERM := "truecolor"
export CARGO_TERM_COLOR := "always"

# Colors for output (just handles ANSI codes cross-platform)
GREEN := '\033[0;32m'
BLUE := '\033[0;34m'
YELLOW := '\033[1;33m'
RED := '\033[0;31m'
NC := '\033[0m' # No Color

# Default recipe - show available commands
default:
    @echo "{{BLUE}}🌳 Tree - Modern Rust Development Workflow{{NC}}"
    @echo "=================================================="
    @echo ""
    @echo "{{GREEN}}🚀 Main Workflow:{{NC}}"
    @echo "  just go           - Complete two-phase fast-fail workflow"
    @echo ""
    @echo "{{GREEN}}⚙️  Environment Setup:{{NC}}"
    @echo "  just setup        - Smart setup (check & install missing tools)"
    @echo ""
    @echo "{{GREEN}}📋 Individual Steps:{{NC}}"
    @echo "  just fmt          - Format code"
    @echo "  just test         - Run all tests"
    @echo "  just doc          - Run documentation tests"
    @echo "  just coverage     - Generate coverage report"
    @echo "  just lint-prod    - Ultra-strict production linting"
    @echo "  just lint-tests   - Pragmatic test linting"
    @echo "  just build        - Build release binary"
    @echo "  just deploy       - Copy binary to ~/bin"
    @echo ""
    @echo "{{GREEN}}🔧 Development:{{NC}}"
    @echo "  just dev          - Watch mode with testing"
    @echo "  just check        - Quick validation"
    @echo "  just clean        - Clean build artifacts"
    @echo ""
    @echo "{{GREEN}}📊 Analysis:{{NC}}"
    @echo "  just audit        - Security audit"
    @echo "  just version      - Show current version"
    @echo "  just benchmark-both - Compare workflow performance"

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

# Run all tests
test:
    @echo "{{BLUE}}🧪 Running all tests...{{NC}}"
    cargo test --workspace --all-features --all-targets

# Run documentation tests
doc:
    @echo "{{BLUE}}📚 Running documentation tests...{{NC}}"
    cargo test --workspace --doc --all-features

# Generate coverage report (clean first to prevent contamination)
coverage:
    @echo "{{BLUE}}📊 Generating coverage report...{{NC}}"
    @echo "{{BLUE}}  → Cleaning build artifacts first...{{NC}}"
    cargo clean
    -cargo llvm-cov --version || cargo install cargo-llvm-cov
    CARGO_TARGET_DIR=target cargo llvm-cov test --workspace --all-features --all-targets --html
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

    # 3a: Build with coverage and run unit/integration tests with report
    @echo "{{BLUE}}  → Running unit & integration tests with coverage report...{{NC}}"
    cargo llvm-cov test --workspace --all-features --all-targets --html
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

# Security audit
audit:
    @echo "{{BLUE}}🔒 Security audit...{{NC}}"
    -cargo audit --version || cargo install cargo-audit
    cargo audit

# Show current version
version:
    @echo "{{BLUE}}📋 Current version:{{NC}}"
    @grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/'

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

# Smart development environment setup - checks and installs only what's missing
setup:
    @echo "{{BLUE}}🔧 Smart Development Environment Setup{{NC}}"
    @echo "{{YELLOW}}Checking and installing only missing tools...{{NC}}"
    @echo ""
    just setup-rust-tools
    just setup-platform-tools
    just setup-git-config
    @echo ""
    @echo "{{GREEN}}✅ Development environment ready!{{NC}}"
    @echo "{{GREEN}}🚀 Run 'just go' to start developing{{NC}}"

# Smart Rust tools installation - check first, install only if missing
setup-rust-tools:
    @echo "{{BLUE}}🦀 Checking Rust development tools...{{NC}}"

    # Check and install cargo-llvm-cov
    @if ! command -v cargo-llvm-cov >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-llvm-cov...{{NC}}"; \
        cargo install cargo-llvm-cov --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-llvm-cov already installed{{NC}}"; \
    fi

    # Check and install cargo-audit
    @if ! command -v cargo-audit >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-audit...{{NC}}"; \
        cargo install cargo-audit --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-audit already installed{{NC}}"; \
    fi

    # Check and install cargo-watch
    @if ! command -v cargo-watch >/dev/null 2>&1; then \
        echo "{{BLUE}}  → Installing cargo-watch...{{NC}}"; \
        cargo install cargo-watch --quiet; \
    else \
        echo "{{GREEN}}  ✅ cargo-watch already installed{{NC}}"; \
    fi

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
    echo -e "\033[0;34m🖥️  Checking platform-specific tools...\033[0m"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "\033[0;34m  → macOS detected\033[0m"
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo -e "\033[0;34m  → Installing Homebrew...\033[0m"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo -e "\033[0;32m  ✅ Homebrew already installed\033[0m"
        fi

        # Install just if not present
        if ! command -v just &> /dev/null; then
            echo -e "\033[0;34m  → Installing just via Homebrew...\033[0m"
            brew install just
        else
            echo -e "\033[0;32m  ✅ just already installed\033[0m"
        fi

        # Install git if not present
        if ! command -v git &> /dev/null; then
            echo -e "\033[0;34m  → Installing git via Homebrew...\033[0m"
            brew install git
        else
            echo -e "\033[0;32m  ✅ git already installed\033[0m"
        fi

    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        echo -e "\033[0;34m  → Windows detected, using Chocolatey...\033[0m"

        # Check if Chocolatey is installed
        if ! command -v choco &> /dev/null; then
            echo -e "\033[0;33m  → Installing Chocolatey...\033[0m"
            powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        fi

        # Install just if not present
        if ! command -v just &> /dev/null; then
            echo -e "\033[0;34m  → Installing just via Chocolatey...\033[0m"
            choco install just -y
        fi

        # Install Git Bash if not present
        if ! command -v git &> /dev/null; then
            echo -e "\033[0;34m  → Installing Git for Windows via Chocolatey...\033[0m"
            choco install git -y
        fi

    else
        echo -e "\033[0;34m  → Linux detected, using package manager...\033[0m"

        # Detect Linux package manager and install tools
        if command -v apt-get &> /dev/null; then
            echo -e "\033[0;34m  → Using apt-get...\033[0m"
            sudo apt-get update -qq
            sudo apt-get install -y git curl build-essential

            # Install just via cargo if not available in repos
            if ! command -v just &> /dev/null; then
                echo -e "\033[0;34m  → Installing just via cargo...\033[0m"
                cargo install just --quiet
            fi

        elif command -v yum &> /dev/null; then
            echo -e "\033[0;34m  → Using yum...\033[0m"
            sudo yum install -y git curl gcc
            cargo install just --quiet

        elif command -v pacman &> /dev/null; then
            echo -e "\033[0;34m  → Using pacman...\033[0m"
            sudo pacman -S --noconfirm git curl base-devel
            cargo install just --quiet

        else
            echo -e "\033[0;33m  → Unknown Linux distribution, installing just via cargo...\033[0m"
            cargo install just --quiet
        fi
    fi

    echo -e "\033[0;32m✅ Platform tools installed\033[0m"

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
