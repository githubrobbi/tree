# Tree - Modern Rust Development Workflow
# Professional CLI tree utility with intelligent ignore patterns
set shell := ["bash", "-uc"]

# Colors for output
GREEN := '\033[0;32m'
BLUE := '\033[0;34m'
YELLOW := '\033[1;33m'
RED := '\033[0;31m'
NC := '\033[0m' # No Color

# Default recipe - show available commands
default:
    @echo -e "{{BLUE}}🌳 Tree - Modern Rust Development Workflow{{NC}}"
    @echo "=================================================="
    @echo ""
    @echo -e "{{GREEN}}🚀 Main Workflow:{{NC}}"
    @echo "  just go           - Complete two-phase fast-fail workflow"
    @echo ""
    @echo -e "{{GREEN}}📋 Individual Steps:{{NC}}"
    @echo "  just fmt          - Format code"
    @echo "  just test         - Run all tests"
    @echo "  just doc          - Run documentation tests"
    @echo "  just coverage     - Generate coverage report"
    @echo "  just lint-prod    - Ultra-strict production linting"
    @echo "  just lint-tests   - Pragmatic test linting"
    @echo "  just build        - Build release binary"
    @echo "  just deploy       - Copy binary to ~/bin"
    @echo ""
    @echo -e "{{GREEN}}🔧 Development:{{NC}}"
    @echo "  just dev          - Watch mode with testing"
    @echo "  just check        - Quick validation"
    @echo "  just clean        - Clean build artifacts"
    @echo ""
    @echo -e "{{GREEN}}📊 Analysis:{{NC}}"
    @echo "  just audit        - Security audit"
    @echo "  just version      - Show current version"

# Common clippy flags - Rust master approach
common_flags := "-D clippy::pedantic -D clippy::nursery -D clippy::cargo -A clippy::multiple_crate_versions -W clippy::panic -W clippy::todo -W clippy::unimplemented -D warnings"
prod_flags := common_flags + " -W clippy::unwrap_used -W clippy::expect_used -W clippy::missing_docs_in_private_items"
test_flags := common_flags + " -A clippy::unwrap_used -A clippy::expect_used"

# ═══════════════════════════════════════════════════════════════════════════
# Individual Step Commands (Granular Control)
# ═══════════════════════════════════════════════════════════════════════════

# Format code
fmt:
    @echo -e "{{BLUE}}📝 Formatting code...{{NC}}"
    cargo fmt --all

# Run all tests
test:
    @echo -e "{{BLUE}}🧪 Running all tests...{{NC}}"
    cargo test --workspace --all-features --all-targets

# Run documentation tests
doc:
    @echo -e "{{BLUE}}📚 Running documentation tests...{{NC}}"
    cargo test --workspace --doc --all-features

# Generate coverage report
coverage:
    @echo -e "{{BLUE}}📊 Generating coverage report...{{NC}}"
    @if command -v cargo-llvm-cov >/dev/null 2>&1; then \
        cargo llvm-cov test --workspace --all-features --all-targets --html; \
        echo -e "{{GREEN}}📁 Coverage report: target/llvm-cov/html/index.html{{NC}}"; \
    else \
        echo -e "{{YELLOW}}Installing cargo-llvm-cov...{{NC}}"; \
        cargo install cargo-llvm-cov; \
        cargo llvm-cov test --workspace --all-features --all-targets --html; \
        echo -e "{{GREEN}}📁 Coverage report: target/llvm-cov/html/index.html{{NC}}"; \
    fi

# Ultra-strict production linting
lint-prod:
    @echo -e "{{BLUE}}🔍 Ultra-strict production linting...{{NC}}"
    cargo clippy --lib --bins -- {{prod_flags}}

# Pragmatic test linting
lint-tests:
    @echo -e "{{BLUE}}🧪 Pragmatic test linting...{{NC}}"
    cargo clippy --tests -- {{test_flags}}

# Build release binary
build:
    @echo -e "{{BLUE}}🔨 Building release binary...{{NC}}"
    cargo build --release

# Deploy binary to ~/bin
deploy:
    @echo -e "{{BLUE}}📦 Deploying binary...{{NC}}"
    just copy-binary release

# ═══════════════════════════════════════════════════════════════════════════
# Development Utilities
# ═══════════════════════════════════════════════════════════════════════════

# Watch mode development
dev:
    @echo -e "{{BLUE}}🔄 Starting watch mode...{{NC}}"
    @if command -v cargo-watch >/dev/null 2>&1; then \
        cargo watch -x "test --workspace" -x "clippy --workspace --all-targets --all-features -- {{test_flags}}"; \
    else \
        echo -e "{{YELLOW}}Installing cargo-watch...{{NC}}"; \
        cargo install cargo-watch; \
        cargo watch -x "test --workspace" -x "clippy --workspace --all-targets --all-features -- {{test_flags}}"; \
    fi

# Quick validation
check:
    @echo -e "{{BLUE}}⚡ Quick validation...{{NC}}"
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
    @echo -e "{{BLUE}}🧪 PHASE 1: Code & Extensive Testing (FAST-FAIL){{NC}}"
    @echo -e "{{YELLOW}}Running MOST extensive tests - STOPPING at FIRST failure...{{NC}}"
    @echo "========================================================"
    @echo ""

    # Step 1: Auto-formatting
    @echo -e "{{BLUE}}Step 1: Auto-formatting code...{{NC}}"
    cargo fmt --all

    # Step 2: Run all tests with coverage data collection (FAST-FAIL)
    @echo -e "{{BLUE}}Step 2: Running all tests with coverage data collection (FAST-FAIL)...{{NC}}"
    @if command -v cargo-llvm-cov >/dev/null 2>&1; then \
        cargo llvm-cov test --workspace --all-features --all-targets --no-report; \
        echo -e "{{GREEN}}✅ All tests passed, coverage data collected{{NC}}"; \
    else \
        echo -e "{{YELLOW}}Installing cargo-llvm-cov...{{NC}}"; \
        cargo install cargo-llvm-cov; \
        cargo llvm-cov test --workspace --all-features --all-targets --no-report; \
        echo -e "{{GREEN}}✅ All tests passed, coverage data collected{{NC}}"; \
    fi

    # Step 3: Generate coverage report
    @echo -e "{{BLUE}}Step 3: Generating coverage report...{{NC}}"
    cargo llvm-cov report --html
    @echo -e "{{GREEN}}📁 Coverage report: target/llvm-cov/html/index.html{{NC}}"

    # Step 4: Documentation tests (FAST-FAIL)
    @echo -e "{{BLUE}}Step 4: Documentation tests validation (FAST-FAIL)...{{NC}}"
    cargo test --workspace --doc --all-features

    # Step 5: Ultra-strict production linting (FAST-FAIL)
    @echo -e "{{BLUE}}Step 5: Ultra-strict production code linting (FAST-FAIL)...{{NC}}"
    just lint-prod

    # Step 6: Pragmatic test linting (FAST-FAIL)
    @echo -e "{{BLUE}}Step 6: Pragmatic test code linting (FAST-FAIL)...{{NC}}"
    just lint-tests

    # Step 7: Format validation (final check) (FAST-FAIL)
    @echo -e "{{BLUE}}Step 7: Final format validation (FAST-FAIL)...{{NC}}"
    cargo fmt --all -- --check

    @echo ""
    @echo -e "{{GREEN}}✅ PHASE 1 FAST-FAIL COMPLETE: All extensive tests passed, code ready for commit!{{NC}}"
    @echo -e "{{BLUE}}💡 Next: Run 'just phase2-ship' when ready to build/commit/push{{NC}}"

# PHASE 2: Version/Build/Deploy (Professional Grade)
phase2-ship:
    @echo -e "{{BLUE}}🚀 PHASE 2: Version/Build/Deploy (Post-Testing){{NC}}"
    @echo -e "{{YELLOW}}Assumes Phase 1 completed: format ✅ clippy ✅ compile ✅ tests ✅{{NC}}"
    @echo "========================================================"
    @echo ""

    # Step 1: Version increment
    @echo -e "{{BLUE}}Step 1: Version increment...{{NC}}"
    @if command -v rust-script >/dev/null 2>&1; then \
        ./build/update_version.rs patch; \
    else \
        echo -e "{{YELLOW}}Installing rust-script...{{NC}}"; \
        cargo install rust-script; \
        ./build/update_version.rs patch; \
    fi

    # Step 2: Build with new version
    @echo -e "{{BLUE}}Step 2: Building release binary with NEW version...{{NC}}"
    cargo build --release

    # Step 3: Copy binary to deployment location
    @echo -e "{{BLUE}}Step 3: Copy binary to deployment location...{{NC}}"
    just copy-binary release

    # Step 4: Add all changes to git
    @echo -e "{{BLUE}}Step 4: Adding all changes to staging area...{{NC}}"
    git add .

    # Step 5: Create auto-generated commit
    @echo -e "{{BLUE}}Step 5: Creating auto-generated commit...{{NC}}"
    git commit -m "chore: release v`grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/'` - comprehensive testing complete [auto-commit]"

    # Step 6: Sync with remote and push
    @echo -e "{{BLUE}}Step 6: Syncing with remote and pushing...{{NC}}"
    git pull origin main --rebase
    git push origin main

    @echo ""
    @echo -e "{{GREEN}}✅ PHASE 2 COMPLETE: Version incremented, built, deployed, committed, and pushed!{{NC}}"



# Complete two-phase fast-fail workflow - perfect for rapid development
go:
    @echo -e "{{BLUE}}🚀 Complete Two-Phase Fast-Fail Workflow{{NC}}"
    @echo -e "{{YELLOW}}Failing fast at ANY error in either phase...{{NC}}"
    @echo "========================================================"
    @echo ""

    # PHASE 1: Comprehensive fast-fail testing and validation
    @echo -e "{{BLUE}}🧪 PHASE 1: Comprehensive Fast-Fail Testing & Validation{{NC}}"
    just phase1-test

    @echo ""
    @echo -e "{{GREEN}}✅ PHASE 1 COMPLETE - All validation passed!{{NC}}"
    @echo -e "{{BLUE}}🚀 Starting PHASE 2: Build/Deploy...{{NC}}"
    @echo ""

    # PHASE 2: Fast-fail build and deployment
    @echo -e "{{BLUE}}📦 PHASE 2: Fast-Fail Build & Deploy{{NC}}"
    just phase2-ship

    @echo ""
    @echo -e "{{GREEN}}🎉 COMPLETE TWO-PHASE FAST-FAIL WORKFLOW FINISHED!{{NC}}"
    @echo -e "{{GREEN}}✅ Phase 1: Testing & Validation{{NC}}"
    @echo -e "{{GREEN}}✅ Phase 2: Build/Commit/Push/Deploy{{NC}}"





# ═══════════════════════════════════════════════════════════════════════════
# Quality Assurance & Analysis
# ═══════════════════════════════════════════════════════════════════════════



# ═══════════════════════════════════════════════════════════════════════════
# Utilities
# ═══════════════════════════════════════════════════════════════════════════

# Security audit
audit:
    @echo -e "{{BLUE}}🔒 Security audit...{{NC}}"
    @if command -v cargo-audit >/dev/null 2>&1; then \
        cargo audit; \
    else \
        echo -e "{{YELLOW}}Installing cargo-audit...{{NC}}"; \
        cargo install cargo-audit; \
        cargo audit; \
    fi

# Show current version
version:
    @echo -e "{{BLUE}}📋 Current version:{{NC}}"
    @grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/'

# Clean build artifacts
clean:
    @echo -e "{{BLUE}}🧹 Cleaning build artifacts...{{NC}}"
    cargo clean

# Test version extraction for commit message
test-version:
    @echo -e "{{BLUE}}🧪 Testing version extraction for commit message...{{NC}}"
    @echo -e "{{YELLOW}}Current Cargo.toml version line:{{NC}}"
    @grep '^version' Cargo.toml | head -1
    @echo -e "{{YELLOW}}Extracted version:{{NC}}"
    @grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/'
    @echo -e "{{YELLOW}}Generated commit message:{{NC}}"
    @echo "chore: release v`grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/'` - comprehensive testing complete [auto-commit]"

# ═══════════════════════════════════════════════════════════════════════════
# Binary Deployment
# ═══════════════════════════════════════════════════════════════════════════

# Copy binary to deployment location (dynamically discovers target directory)
copy-binary profile:
    @echo -e "{{BLUE}}📦 Copying {{profile}} binary to deployment location...{{NC}}"
    @if [ -d "$HOME/bin/rust" ]; then \
        SOURCE_DIR="$HOME/bin/rust/{{profile}}"; \
    else \
        SOURCE_DIR="target/{{profile}}"; \
    fi; \
    if [ ! -d "$SOURCE_DIR" ]; then \
        echo -e "{{RED}}❌ Source directory not found: $SOURCE_DIR{{NC}}"; \
        echo -e "{{YELLOW}}💡 Run 'cargo build --{{profile}}' first{{NC}}"; \
        exit 1; \
    fi; \
    BINARY_COUNT=0; \
    for BINARY_PATH in "$SOURCE_DIR"/*; do \
        if [ -f "$BINARY_PATH" ] && [ -x "$BINARY_PATH" ]; then \
            BINARY_NAME=$(basename "$BINARY_PATH"); \
            case "$BINARY_NAME" in \
                lib*|*.rlib|*.d|*.so|*.dylib|*.dll) \
                    continue ;; \
                *) \
                    DEST_PATH="$HOME/bin/$BINARY_NAME"; \
                    echo -e "{{BLUE}}  → Source: $BINARY_PATH{{NC}}"; \
                    echo -e "{{BLUE}}  → Destination: $DEST_PATH{{NC}}"; \
                    if cp "$BINARY_PATH" "$DEST_PATH" && chmod +x "$DEST_PATH"; then \
                        echo -e "{{GREEN}}✅ $BINARY_NAME copied and permissions set{{NC}}"; \
                        if command -v xattr >/dev/null 2>&1; then \
                            xattr -w com.tree.buildtype "{{profile}}" "$DEST_PATH" 2>/dev/null || true; \
                            echo -e "{{GREEN}}🏷️  Extended attributes set for $BINARY_NAME{{NC}}"; \
                        fi; \
                        BINARY_COUNT=$((BINARY_COUNT + 1)); \
                    else \
                        echo -e "{{RED}}❌ Failed to copy $BINARY_NAME{{NC}}"; \
                        exit 1; \
                    fi ;; \
            esac; \
        fi; \
    done; \
    if [ $BINARY_COUNT -eq 0 ]; then \
        echo -e "{{RED}}❌ No executable binaries found in $SOURCE_DIR{{NC}}"; \
        exit 1; \
    else \
        echo -e "{{GREEN}}✅ Successfully copied $BINARY_COUNT binaries to ~/bin{{NC}}"; \
    fi
