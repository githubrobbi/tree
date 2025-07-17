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
    @echo -e "{{GREEN}}Development Commands:{{NC}}"
    @echo "  just dev          - Modern watch mode with testing"
    @echo "  just test         - Run all tests"
    @echo "  just check        - Quick code validation"
    @echo ""
    @echo -e "{{GREEN}}Quality Assurance:{{NC}}"
    @echo "  just ci           - Comprehensive CI checks"
    @echo "  just lint-prod    - Ultra-strict production linting"
    @echo "  just lint-tests   - Pragmatic test linting"
    @echo "  just lint-all     - Mixed approach (default)"
    @echo "  just fmt          - Format code"
    @echo "  just coverage     - Coverage analysis"
    @echo ""
    @echo -e "{{GREEN}}Two-Phase Professional Workflow:{{NC}}"
    @echo "  just phase1-test  - Phase 1: Coverage + Tests + Lint (Prod & Tests)"
    @echo "  just phase2-ship  - Phase 2: Build/Commit/Push/Deploy"
    @echo "  just dev-workflow - Complete two-phase workflow"
    @echo ""
    @echo -e "{{GREEN}}Performance & Analysis:{{NC}}"
    @echo "  just bench        - Run benchmarks"
    @echo "  just audit        - Security audit"
    @echo ""
    @echo -e "{{GREEN}}Utilities:{{NC}}"
    @echo "  just clean        - Clean build artifacts"
    @echo "  just install-tools - Install development tools"
    @echo "  just version      - Show current version"

# Common clippy flags - Rust master approach
common_flags := "-D clippy::pedantic -D clippy::nursery -D clippy::cargo -A clippy::multiple_crate_versions -W clippy::panic -W clippy::todo -W clippy::unimplemented -D warnings"
prod_flags := common_flags + " -W clippy::unwrap_used -W clippy::expect_used -W clippy::missing_docs_in_private_items"
test_flags := common_flags + " -A clippy::unwrap_used -A clippy::expect_used"

# Modern development workflow with watch mode
dev:
    @echo -e "{{BLUE}}🔄 Starting modern development workflow...{{NC}}"
    @if command -v cargo-watch >/dev/null 2>&1; then \
        cargo watch -x "test --workspace" -x "clippy --workspace --all-targets --all-features -- {{test_flags}}"; \
    else \
        echo -e "{{YELLOW}}Installing cargo-watch...{{NC}}"; \
        cargo install cargo-watch; \
        cargo watch -x "test --workspace" -x "clippy --workspace --all-targets --all-features -- {{test_flags}}"; \
    fi

# Modern testing
test:
    @echo -e "{{BLUE}}🧪 Running all tests...{{NC}}"
    cargo test --workspace --all-features --all-targets

# Quick code validation
check:
    @echo -e "{{BLUE}}⚡ Quick validation...{{NC}}"
    cargo check --workspace --all-targets --all-features
    cargo fmt --all -- --check

# Comprehensive CI checks (Streamlined - use phase1-test for full workflow)
ci:
    @echo -e "{{BLUE}}🔬 Comprehensive CI Checks{{NC}}"
    @echo "================================"
    @echo ""

    # Step 1: Format check
    @echo -e "{{YELLOW}}📝 Format validation...{{NC}}"
    cargo fmt --all -- --check

    # Step 2: Production linting
    @echo -e "{{YELLOW}}🔍 Production code linting...{{NC}}"
    just lint-prod

    # Step 3: Test suite
    @echo -e "{{YELLOW}}🧪 Test suite...{{NC}}"
    cargo test --workspace --all-features --all-targets

    # Step 4: Documentation tests
    @echo -e "{{YELLOW}}📚 Documentation tests...{{NC}}"
    cargo test --workspace --doc --all-features

    @echo -e "{{GREEN}}✅ All CI checks passed!{{NC}}"
    @echo -e "{{BLUE}}💡 For full coverage analysis, use 'just phase1-test'{{NC}}"

# ═══════════════════════════════════════════════════════════════════════════
# Professional Two-Phase Development Workflow
# ═══════════════════════════════════════════════════════════════════════════
# Phase 1: Code & Extensive Testing (Manual Trigger)
# Phase 2: Build/Commit/Push/Deploy (Manual Trigger)
# ═══════════════════════════════════════════════════════════════════════════

# PHASE 1: Code & Extensive Testing (Professional Grade)
phase1-test:
    @echo -e "{{BLUE}}🧪 PHASE 1: Code & Extensive Testing{{NC}}"
    @echo -e "{{YELLOW}}Running MOST extensive tests to find/fix all errors...{{NC}}"
    @echo "========================================================"
    @echo ""

    # Step 1: Auto-formatting
    @echo -e "{{BLUE}}Step 1: Auto-formatting code...{{NC}}"
    cargo fmt --all

    # Step 2: Run all tests with coverage data collection
    @echo -e "{{BLUE}}Step 2: Running all tests with coverage data collection...{{NC}}"
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

    # Step 4: Documentation tests
    @echo -e "{{BLUE}}Step 4: Documentation tests validation...{{NC}}"
    cargo test --workspace --doc --all-features

    # Step 5: Ultra-strict production linting
    @echo -e "{{BLUE}}Step 5: Ultra-strict production code linting...{{NC}}"
    just lint-prod

    # Step 6: Pragmatic test linting
    @echo -e "{{BLUE}}Step 6: Pragmatic test code linting...{{NC}}"
    just lint-tests

    # Step 7: Format validation (final check)
    @echo -e "{{BLUE}}Step 7: Final format validation...{{NC}}"
    cargo fmt --all -- --check

    @echo ""
    @echo -e "{{GREEN}}✅ PHASE 1 COMPLETE: All tests passed, code ready for commit!{{NC}}"
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
    @NEW_VERSION=`grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/'`; \
    git commit -m "chore: release v$$NEW_VERSION - comprehensive testing complete [auto-commit]"

    # Step 6: Sync with remote and push
    @echo -e "{{BLUE}}Step 6: Syncing with remote and pushing...{{NC}}"
    git pull origin main --rebase
    git push origin main

    @echo ""
    @echo -e "{{GREEN}}✅ PHASE 2 COMPLETE: Version incremented, built, deployed, committed, and pushed!{{NC}}"

# Complete two-phase workflow (for full automation)
dev-workflow:
    @echo -e "{{BLUE}}🔄 Complete Two-Phase Development Workflow{{NC}}"
    @echo -e "{{YELLOW}}Phase 1: Code & Extensive Testing...{{NC}}"
    just phase1-test
    @echo -e "{{YELLOW}}Phase 2: Build/Commit/Push/Deploy...{{NC}}"
    just phase2-ship
    @echo -e "{{GREEN}}🎉 Complete development workflow finished!{{NC}}"

# ═══════════════════════════════════════════════════════════════════════════
# Rust Master Linting Commands
# ═══════════════════════════════════════════════════════════════════════════

# Ultra-strict production linting
lint-prod:
    @echo -e "{{BLUE}}🔍 Ultra-strict production linting...{{NC}}"
    @echo -e "{{YELLOW}}   → Pedantic: Very strict style/performance lints{{NC}}"
    @echo -e "{{YELLOW}}   → Nursery: Experimental bleeding-edge lints{{NC}}"
    @echo -e "{{YELLOW}}   → Cargo: Cargo.toml best practices{{NC}}"
    @echo -e "{{YELLOW}}   → Unwrap/Expect: Forbidden in production{{NC}}"
    cargo clippy --lib --bins -- {{prod_flags}}
    @echo -e "{{GREEN}}✅ Production code passes ultra-strict checks!{{NC}}"

# Pragmatic test linting
lint-tests:
    @echo -e "{{BLUE}}🧪 Pragmatic test linting...{{NC}}"
    @echo -e "{{YELLOW}}   → Unwrap/Expect: Allowed for fast test failures{{NC}}"
    @echo -e "{{YELLOW}}   → Focus: Logic issues, not defensive programming{{NC}}"
    cargo clippy --tests -- {{test_flags}}
    @echo -e "{{GREEN}}✅ Test code passes pragmatic checks!{{NC}}"

# Mixed approach linting (default)
lint-all:
    @echo -e "{{BLUE}}🌍 Mixed approach linting...{{NC}}"
    @echo -e "{{YELLOW}}   → Production rules for src/, pragmatic for tests/{{NC}}"
    cargo clippy --workspace --all-targets --all-features -- {{test_flags}}
    @echo -e "{{GREEN}}✅ All code passes mixed approach checks!{{NC}}"

# Default lint command
lint: lint-all

# ═══════════════════════════════════════════════════════════════════════════
# Quality Assurance & Analysis
# ═══════════════════════════════════════════════════════════════════════════

# Format code
fmt:
    @echo -e "{{BLUE}}📝 Formatting code...{{NC}}"
    cargo fmt --all

# Check formatting
fmt-check:
    @echo -e "{{BLUE}}🔍 Checking formatting...{{NC}}"
    cargo fmt --all -- --check

# Coverage analysis
coverage:
    @echo -e "{{BLUE}}📊 Running coverage analysis...{{NC}}"
    @if command -v cargo-llvm-cov >/dev/null 2>&1; then \
        cargo llvm-cov --workspace --html; \
        echo -e "{{GREEN}}📁 Coverage report: target/llvm-cov/html/index.html{{NC}}"; \
    else \
        echo -e "{{YELLOW}}Installing cargo-llvm-cov...{{NC}}"; \
        cargo install cargo-llvm-cov; \
        cargo llvm-cov --workspace --html; \
        echo -e "{{GREEN}}📁 Coverage report: target/llvm-cov/html/index.html{{NC}}"; \
    fi

# Run benchmarks
bench:
    @echo -e "{{BLUE}}⚡ Running benchmarks...{{NC}}"
    cargo bench --workspace

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

# ═══════════════════════════════════════════════════════════════════════════
# Utilities
# ═══════════════════════════════════════════════════════════════════════════

# Show current version
version:
    @echo -e "{{BLUE}}📋 Current version:{{NC}}"
    @grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/'

# Clean build artifacts
clean:
    @echo -e "{{BLUE}}🧹 Cleaning build artifacts...{{NC}}"
    cargo clean

# Install all development tools
install-tools:
    @echo -e "{{BLUE}}🔧 Installing development tools...{{NC}}"
    @echo -e "{{YELLOW}}Installing essential Rust development tools...{{NC}}"
    cargo install just cargo-llvm-cov cargo-watch cargo-audit
    @echo -e "{{GREEN}}✅ All development tools installed!{{NC}}"

# Development status check
dev-status:
    @echo -e "{{BLUE}}📊 Development Status Check{{NC}}"
    @echo -e "{{YELLOW}}Git status:{{NC}}"
    git status --short
    @echo -e "{{YELLOW}}Current version:{{NC}}"
    just version
    @echo -e "{{YELLOW}}Last commit:{{NC}}"
    git log -1 --oneline
    @echo -e "{{YELLOW}}Branch:{{NC}}"
    git branch --show-current
    @echo -e "{{GREEN}}✅ Status check complete{{NC}}"

# ═══════════════════════════════════════════════════════════════════════════
# Binary Deployment
# ═══════════════════════════════════════════════════════════════════════════

# Copy binary to deployment location (dynamically discovers target directory)
copy-binary profile:
    @echo -e "{{BLUE}}📦 Copying {{profile}} binary to deployment location...{{NC}}"
    @if [ -d "/Users/rnio/bin/rust" ]; then \
        SOURCE_DIR="/Users/rnio/bin/rust/{{profile}}"; \
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
                    DEST_PATH="/Users/rnio/bin/$BINARY_NAME"; \
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
