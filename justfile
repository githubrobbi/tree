# Tree – Modern Rust Development Workflow (cross-platform & Git-Bash-friendly)
#
# ═══════════════════════════════════════════════════════════════════════════════
# 🎓 LEARNING GUIDE: Cross-Platform Build System Masterclass
# ═══════════════════════════════════════════════════════════════════════════════
#
# This justfile is designed as both a working build system AND an educational
# resource. Every design decision, workaround, and quirk is documented to help
# junior programmers understand the complexities of cross-platform development.
#
# 📚 WHAT YOU'LL LEARN:
# • How to handle shell differences between Windows PowerShell, Git Bash, and Unix
# • Why certain approaches fail and what works instead
# • Cross-platform binary handling and PATH management
# • Professional development workflow design (two-phase fast-fail)
# • Tool ecosystem management and dependency handling
# • Color system implementation across different terminals
# • Platform detection strategies and their trade-offs
#
# 🔍 HOW TO READ THIS FILE:
# • Each section explains WHY before showing HOW
# • Failed approaches are documented to prevent repeating mistakes
# • Cross-references help you understand relationships between concepts
# • Examples show what happens when you don't follow the patterns
#
# ═══════════════════════════════════════════════════════════════════════════════
# 📋 CRITICAL DESIGN DECISIONS & PLATFORM QUIRKS
# ═══════════════════════════════════════════════════════════════════════════════
#
# This justfile has been battle-tested across Windows, macOS, and Linux with
# specific workarounds for cross-platform compatibility. Each quirk below
# represents hours of debugging and testing. Please read before making changes.
#
# 🔧 SHELL CONFIGURATION STRATEGY:
# ─────────────────────────────────────────────────────────────────────────────
# PROBLEM: Different platforms use different shells with incompatible syntax
# • Windows: PowerShell (doesn't understand bash syntax like ||, &&, if)
# • macOS/Linux: bash/zsh (don't understand PowerShell syntax)
# • Git Bash on Windows: bash-compatible but path resolution issues
#
# SOLUTION: Hybrid approach with explicit shell control
# • set shell := ["bash", "-euo", "pipefail", "-c"] - Global bash preference
#   - "-e" = exit on any error (fast-fail behavior)
#   - "-u" = exit on undefined variables (catch typos)
#   - "-o pipefail" = exit if any command in pipeline fails
# • set windows-shell := ["powershell.exe", ...] - Fallback (rarely used)
# • #!/usr/bin/env bash shebang on ALL recipes with logic/colors
#
# WHY THIS WORKS:
# • Forces bash execution even when just defaults to PowerShell
# • Ensures consistent behavior across all platforms
# • Provides fast-fail behavior that stops on first error
#
# WHAT FAILS WITHOUT THIS:
# • PowerShell: "if ! command -v tool" → syntax error
# • PowerShell: "command && other_command" → syntax error
# • Mixed shells: inconsistent variable expansion and error handling
#
# 🎨 COLOR SYSTEM IMPLEMENTATION:
# ─────────────────────────────────────────────────────────────────────────────
# PROBLEM: Cross-platform color support is surprisingly complex
# • just variable expansion ({{GREEN}}) fails on some platforms
# • @echo shows raw ANSI codes instead of colors
# • Different terminals have different color support
# • NO_COLOR environment variable must be respected
#
# FAILED APPROACHES (documented to prevent repetition):
# ❌ Color variables with just expansion: {{GREEN}} shows as literal "{{GREEN}}"
# ❌ @echo with ANSI codes: displays "\033[0;32m" instead of green text
# ❌ Dynamic color detection: inconsistent between Windows/Unix
# ❌ Shell-specific color commands: breaks cross-platform compatibility
#
# ✅ WORKING SOLUTION: Direct ANSI codes with @printf
# • Hardcoded ANSI escape sequences: \033[0;34m (blue), \033[0;32m (green)
# • @printf with \n for consistent newline handling
# • NO_COLOR support through environment variable detection
# • Colors used consistently:
#   - \033[0;34m = Blue (info/steps)
#   - \033[0;32m = Green (success)
#   - \033[1;33m = Yellow (warnings)
#   - \033[0;31m = Red (errors)
#   - \033[0m = Reset to default
#
# 🪟 WINDOWS COMPATIBILITY DEEP DIVE:
# ─────────────────────────────────────────────────────────────────────────────
# PROBLEM: Windows PowerShell is fundamentally different from Unix shells
#
# SPECIFIC ISSUES ENCOUNTERED:
# • PowerShell syntax: if ($condition) { } vs bash: if [ condition ]; then
# • Command chaining: PowerShell uses ; vs bash uses && and ||
# • Path separators: PowerShell uses \ vs bash uses /
# • Binary names: Windows adds .exe extension automatically
# • Environment variables: PowerShell uses $env:VAR vs bash uses $VAR
# • Command availability: PowerShell uses Get-Command vs bash uses command -v
#
# SOLUTION: Force bash execution everywhere
# • #!/usr/bin/env bash shebang on ALL recipes with logic
# • Git Bash provides Unix-like environment on Windows
# • @just (not just) for sub-recipe calls to avoid shell context issues
#
# WHY @just vs just MATTERS:
# • @just: Executes in current shell context (inherits bash from shebang)
# • just: May spawn new shell (could default to PowerShell on Windows)
# • Example failure: "just _install-tool" in PowerShell → command not found
# • Example success: "@just _install-tool" in bash → works correctly
#
# WINDOWS SETUP REQUIREMENTS:
# • Git for Windows (provides Git Bash)
# • Optional: 'jb' alias → just --shell 'C:\Program Files\Git\bin\bash.exe'
# • Alternative: Use Git Bash terminal instead of PowerShell
#
# 🔄 TOOL INSTALLATION PHILOSOPHY:
# ─────────────────────────────────────────────────────────────────────────────
# PROBLEM: Installing multiple tools can fail in complex ways
# • Network issues during installation
# • Dependency conflicts between tools
# • Platform-specific installation methods
# • Version compatibility issues
#
# SOLUTION: Isolated, idempotent installation pattern
# • Individual @just calls instead of bash loops (Windows PowerShell compatibility)
# • Each tool installation is isolated (one failure doesn't break others)
# • Idempotent design: tools only installed if missing (safe to re-run)
# • cargo-binstall preference: faster binary downloads vs compilation
# • Graceful fallbacks: cargo install if cargo-binstall unavailable
#
# WHY NOT BASH LOOPS:
# • FAILED: for tool in $tools; do just _install $tool; done
# • PROBLEM: PowerShell doesn't understand bash for-loop syntax
# • SOLUTION: Explicit individual calls - more verbose but cross-platform
# • BENEFIT: Clear error messages showing exactly which tool failed
#
# 🚀 TWO-PHASE WORKFLOW DESIGN:
# ─────────────────────────────────────────────────────────────────────────────
# PHILOSOPHY: Separate testing from deployment for professional development
#
# PHASE 1 (phase1-test): Comprehensive validation
# • Clean build artifacts (prevent cross-project contamination)
# • Format code automatically
# • Run all tests with coverage (llvm-cov for efficiency)
# • Run documentation tests separately (avoid duplicate compilation)
# • Ultra-strict linting for production code
# • Pragmatic linting for test code (allows unwrap/expect for clarity)
# • Format validation (ensure code stays formatted)
#
# PHASE 2 (phase2-ship): Version and deploy
# • Version increment (automated)
# • Release build
# • Binary deployment to ~/bin
# • Git commit with auto-generated message
# • Push to remote
#
# WHY TWO PHASES:
# • Phase 1 can be run repeatedly during development
# • Phase 2 only runs when ready to ship (prevents unnecessary commits)
# • Fast-fail behavior: any error stops entire workflow immediately
# • Clear separation of concerns: testing vs deployment
#
# FAST-FAIL STRATEGY:
# • bash -euo pipefail ensures ANY command failure stops execution
# • Prevents cascading failures and wasted time on broken code
# • Clear error messages show exactly where failure occurred
# • Example: test failure stops workflow before attempting to commit
#
# ⚠️  TESTING REQUIREMENTS BEFORE CHANGES:
# ─────────────────────────────────────────────────────────────────────────────
# This justfile must work on ALL platforms. Test these scenarios:
#
# 1. PLATFORMS:
#    • Windows PowerShell + Git Bash
#    • macOS Terminal + Homebrew
#    • Linux (Ubuntu/Debian, RHEL/CentOS, Arch)
#
# 2. SCENARIOS:
#    • Fresh environment: just setup (installs all tools)
#    • Complete workflow: just go (end-to-end testing)
#    • No color mode: NO_COLOR=1 just go
#    • Individual commands: just test, just build, etc.
#
# 3. VALIDATION:
#    • Colors display correctly (not as raw escape codes)
#    • Fast-fail behavior works (stops on first error)
#    • Cross-platform binary naming (tree vs tre.exe)
#    • PATH setup guidance is accurate
#
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────
# Global shell (strict-mode)
# ─────────────────────────────────────────
set shell         := ["bash", "-euo", "pipefail", "-c"]
set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# ─────────────────────────────────────────
# Colour support (auto-disables if NO_COLOR)
# ─────────────────────────────────────────
# NOTE: These environment variables help tools display colors correctly
export FORCE_COLOR      := "1"
export CLICOLOR_FORCE   := "1"
export TERM             := "xterm-256color"
export COLORTERM        := "truecolor"
export CARGO_TERM_COLOR := "always"

# ⚠️  LEGACY COLOR VARIABLES - DO NOT USE IN RECIPES!
# ─────────────────────────────────────────────────────────────────────────────
# These variables are kept for reference but are NOT used in recipes because
# just does NOT expand them correctly across platforms. Instead, we use
# hardcoded ANSI escape sequences directly in echo statements.
#
# FAILED ATTEMPTS:
# • {{GREEN}} expansion shows literal "{{GREEN}}" instead of color codes
# • Variable substitution inconsistent between Windows/Unix
# • Color detection logic works but expansion fails
#
# WORKING SOLUTION: Direct ANSI codes like \033[0;32m in each echo
# ─────────────────────────────────────────────────────────────────────────────
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
    @echo "  just install      # Install binary to ~/bin (tre.exe on Windows)"
    @echo "  just deploy       # Deploy binary (alias for install)"
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
# 🔧 CRITICAL: These recipes use #!/usr/bin/env bash shebang
# WHY: Windows PowerShell cannot parse bash syntax like:
# • if ! command -v tool
# • command && other_command
# • variable assignments in conditionals
# SOLUTION: Force bash execution even on Windows
# ─────────────────────────────────────────────────────────────────────────────

_install-if-missing TOOL CRATE:
    #!/usr/bin/env bash
    # Idempotent tool installation - only installs if missing
    if ! command -v {{TOOL}} >/dev/null 2>&1; then
        echo "📦 Installing {{CRATE}} …"
        # Prefer cargo-binstall for speed, fallback to cargo install
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
    # Idempotent rustup component installation
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
# 🧰 DEVELOPMENT TOOL ECOSYSTEM
# ─────────────────────────────────────────
# This section defines all tools used in the development workflow.
# Each tool serves a specific purpose in the professional development process.
#
# 📦 CARGO TOOLS (installed via cargo install or cargo-binstall):
# • cargo-binstall    - Fast binary installation (avoids compilation)
# • cargo-watch       - File watching for continuous development
# • cargo-nextest     - Next-generation test runner (faster than cargo test)
# • cargo-llvm-cov    - Code coverage with LLVM (integrates with testing)
# • cargo-deny        - Dependency analysis and license checking
# • cargo-audit       - Security vulnerability scanning
# • cargo-outdated    - Find outdated dependencies
# • cargo-udeps       - Find unused dependencies (requires nightly)
# • cargo-machete     - Remove unused dependencies automatically
# • cargo-expand      - Macro expansion for debugging
# • cargo-geiger      - Unsafe code detection and analysis
# • cargo-criterion   - Advanced benchmarking framework
# • cargo-tarpaulin   - Alternative coverage tool (Linux-focused)
# • rust-script       - Run Rust files as scripts
#
# 🦀 RUSTUP COMPONENTS (installed via rustup component add):
# • llvm-tools-preview - LLVM tools for coverage and analysis
# • miri               - Interpreter for detecting undefined behavior
#
# 💡 TOOL SELECTION RATIONALE:
# • Prefer tools that work across all platforms
# • Choose tools that integrate well together (e.g., nextest + llvm-cov)
# • Include both essential tools (testing, linting) and advanced tools (miri, geiger)
# • Maintain compatibility with both stable and nightly Rust
#
# 🔧 MAINTENANCE NOTES:
# • cargo-tarpaulin: Linux-focused, kept for compatibility but llvm-cov preferred
# • rust-script: Utility tool, not used in main workflow but useful for scripts
# • Update this list when adding/removing tools from the workflow

all_tools       := "cargo-binstall cargo-watch cargo-nextest cargo-llvm-cov cargo-deny cargo-audit cargo-outdated cargo-udeps cargo-machete cargo-expand cargo-geiger cargo-criterion cargo-tarpaulin rust-script"
rust_components := "llvm-tools-preview miri"

# ─────────────────────────────────────────
# Universal setup (idempotent + fast-fail)
# ─────────────────────────────────────────
# 🔧 DESIGN DECISION: Individual just calls instead of bash loops
# WHY: Windows PowerShell compatibility + better error isolation
# ALTERNATIVE THAT FAILED: tools="list"; for t in $tools; do just _install $t; done
# PROBLEM: PowerShell doesn't understand bash for-loop syntax
# SOLUTION: Explicit individual calls - more verbose but cross-platform
# BENEFIT: If one tool fails, you know exactly which one
# ─────────────────────────────────────────────────────────────────────────────

setup:
    @echo "🔧 Universal Smart Development Environment Setup"
    @echo ""
    @echo "🦀 Installing Rust CLI tools (idempotent)"
    @echo ""
    @just _install-if-missing cargo-binstall cargo-binstall
    @just _install-if-missing cargo-watch cargo-watch
    @just _install-if-missing cargo-nextest cargo-nextest
    @just _install-if-missing cargo-llvm-cov cargo-llvm-cov
    @just _install-if-missing cargo-deny cargo-deny
    @just _install-if-missing cargo-audit cargo-audit
    @just _install-if-missing cargo-outdated cargo-outdated
    @just _install-if-missing cargo-udeps cargo-udeps
    @just _install-if-missing cargo-machete cargo-machete
    @just _install-if-missing cargo-expand cargo-expand
    @just _install-if-missing cargo-geiger cargo-geiger
    @just _install-if-missing cargo-criterion cargo-criterion
    @just _install-if-missing cargo-tarpaulin cargo-tarpaulin
    @just _install-if-missing rust-script rust-script
    @echo ""
    @echo "🔧 Adding rustup components"
    @echo ""
    @just _install-component llvm-tools-preview
    @just _install-component miri
    @echo ""
    @echo "✅ Rust toolchain ready!"
    @echo ""
    @just setup-platform-tools
    @just setup-git-config
    @echo ""
    @echo "✅ Development environment ready!"

# ─────────────────────────────────────────
# 🔍 CLIPPY LINTING STRATEGY: World-Class Rust Practices
# ─────────────────────────────────────────
# This section implements a sophisticated linting strategy that balances
# code quality with developer productivity. Different rules apply to
# production code vs test code, reflecting real-world best practices.
#
# 📊 LINTING PHILOSOPHY:
# • Production code: Ultra-strict (library-quality standards)
# • Test code: Pragmatic (clarity over pedantic correctness)
# • Common base: Shared rules that apply to all code
#
# 🎯 CLIPPY LINT LEVELS EXPLAINED:
# • -D (deny): Treat as compilation error (stops build)
# • -W (warn): Show warning but allow compilation
# • -A (allow): Suppress the lint entirely
#
# 🔧 COMMON FLAGS (applied to all code):
# • clippy::pedantic: Comprehensive style and correctness checks
# • clippy::nursery: Experimental lints (cutting-edge practices)
# • clippy::cargo: Cargo.toml and dependency-related lints
# • clippy::multiple_crate_versions: Allowed (common in large projects)
# • clippy::panic/todo/unimplemented: Warn about temporary code
# • warnings: Treat all warnings as errors (zero-warning policy)
#
# 🏭 PRODUCTION FLAGS (library-quality standards):
# • clippy::unwrap_used: Forbidden (use proper error handling)
# • clippy::expect_used: Forbidden (use Result/Option patterns)
# • clippy::missing_docs_in_private_items: Required (comprehensive docs)
#
# 🧪 TEST FLAGS (pragmatic for test clarity):
# • clippy::unwrap_used: Allowed (tests can unwrap for clarity)
# • clippy::expect_used: Allowed (descriptive test failures)
# • Rationale: Test code prioritizes readability over error handling
# ─────────────────────────────────────────────────────────────────────────────
common_flags := "-D clippy::pedantic -D clippy::nursery -D clippy::cargo -A clippy::multiple_crate_versions -W clippy::panic -W clippy::todo -W clippy::unimplemented -D warnings"
prod_flags   := common_flags + " -W clippy::unwrap_used -W clippy::expect_used -W clippy::missing_docs_in_private_items"
test_flags   := common_flags + " -A clippy::unwrap_used -A clippy::expect_used"

# ─────────────────────────────────────────
# Formatting & testing
# ─────────────────────────────────────────
fmt:
    #!/usr/bin/env bash
    echo "\033[0;34m📝 Formatting code…\033[0m"
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
    #!/usr/bin/env bash
    echo "\033[0;34m📚 Running documentation tests…\033[0m"
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

# Ultra-strict production linting (FAST-FAIL)
lint-prod:
    @printf "\033[0;34m🔍 Ultra-strict production linting (FAST-FAIL)...\033[0m\n"
    cargo clippy --workspace --lib --bins --all-features -- {{prod_flags}}

# Pragmatic test linting (FAST-FAIL)
lint-tests:
    @printf "\033[0;34m🧪 Pragmatic test linting (FAST-FAIL)...\033[0m\n"
    cargo clippy --workspace --tests --all-features -- {{test_flags}}

build:
    cargo build --release

# Deploy release binary to ~/bin (cross-platform)
deploy:
    just copy-binary release

# Install release binary to ~/bin (build + copy to ~/bin)
install:
    @printf "\033[0;34m🚀 Installing tree binary to ~/bin...\033[0m\n"
    @just copy-binary release

dev:
    #!/usr/bin/env bash
    echo "\033[0;34m🔄 Starting watch mode…\033[0m"
    if ! command -v cargo-watch >/dev/null 2>&1; then
        # NOTE: Using 'just' (not @just) here because we're inside a bash script
        # The #!/usr/bin/env bash shebang ensures bash context, so 'just' works correctly
        just _install-if-missing cargo-watch cargo-watch
    fi
    cargo watch -x "test --workspace --all-features" -x "clippy --workspace --all-targets --all-features -- {{test_flags}}"

check:
    cargo check --workspace --all-targets --all-features
    cargo fmt --all -- --check

clean:
    cargo clean

# 🚀 CROSS-PLATFORM BINARY DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────
# This recipe handles the complexities of deploying binaries across different
# platforms, including path resolution, binary naming, and permissions.
#
# CROSS-PLATFORM CHALLENGES SOLVED:
# • Target directory location varies (CARGO_TARGET_DIR vs default)
# • Binary names differ (tree vs tree.exe)
# • Windows tree.exe conflicts with system tree command
# • Permission handling differs between Unix and Windows
# • PATH setup guidance varies by platform
#
# IMPLEMENTATION DETAILS:
# • Uses cargo metadata to find actual target directory (handles CARGO_TARGET_DIR)
# • Platform detection via $OSTYPE and $WINDIR environment variables
# • Windows: Renames to tre.exe to avoid conflict with system tree.exe
# • Unix: Keeps original tree name and sets executable permissions
# • Provides platform-specific PATH setup guidance
copy-binary profile:
    #!/usr/bin/env bash
    cargo build --{{profile}}

    # Create ~/bin directory if it doesn't exist
    mkdir -p ~/bin

    # Get the actual target directory from cargo metadata
    # WHY: Some systems use CARGO_TARGET_DIR, others use default target/
    TARGET_DIR=$(cargo metadata --format-version 1 --no-deps | grep -o '"target_directory":"[^"]*"' | cut -d'"' -f4)

    # Determine source and target binary names based on OS
    # PLATFORM DETECTION: Uses multiple methods for reliability
    if [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]] || [[ -n "$WINDIR" ]]; then
        SOURCE_BINARY="tree.exe"
        TARGET_BINARY="tre.exe"  # Rename to avoid Windows tree.exe conflict
    else
        SOURCE_BINARY="tree"
        TARGET_BINARY="tree"
    fi

    # Construct the full path to the source binary
    SOURCE_PATH="$TARGET_DIR/{{profile}}/$SOURCE_BINARY"

    # Verify the binary exists
    if [[ ! -f "$SOURCE_PATH" ]]; then
        printf "\033[0;31m❌ Binary not found at: $SOURCE_PATH\033[0m\n"
        printf "\033[1;33m💡 Build may have failed or binary name mismatch\033[0m\n"
        exit 1
    fi

    # Copy binary to ~/bin with target name
    cp "$SOURCE_PATH" ~/bin/$TARGET_BINARY

    # Set executable permissions on Unix-like systems
    if [[ "$OSTYPE" != "msys"* ]] && [[ "$OSTYPE" != "cygwin"* ]] && [[ -z "$WINDIR" ]]; then
        chmod +x ~/bin/$TARGET_BINARY
    fi

    printf "\033[0;32m✅ Binary installed to ~/bin/$TARGET_BINARY\033[0m\n"
    printf "\033[0;34m📁 Source: $SOURCE_PATH\033[0m\n"

    # Check if ~/bin is in PATH and provide guidance if not
    # Inline the _check-path logic to avoid @just call inside bash script
    HOME_BIN="$HOME/bin"

    if echo "$PATH" | grep -q "$HOME_BIN"; then
        # PATH is configured - provide success message with platform-specific binary name
        if [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]] || [[ -n "$WINDIR" ]]; then
            printf "\033[0;32m🎯 Ready to use: tre (renamed to avoid Windows tree.exe conflict)\033[0m\n"
        else
            printf "\033[0;32m🎯 Ready to use: tree\033[0m\n"
        fi
    else
        # PATH needs configuration - provide platform-specific guidance
        printf "\033[1;33m⚠️  ~/bin is not in your PATH\033[0m\n"
        printf "\033[0;34m💡 Add this to your shell configuration:\033[0m\n"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            printf "\033[0;36m   echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc\033[0m\n"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            printf "\033[0;36m   echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc\033[0m\n"
        elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]] || [[ -n "$WINDIR" ]]; then
            printf "\033[0;36m   Add %USERPROFILE%\\bin to your PATH via System Properties\033[0m\n"
        else
            printf "\033[0;36m   export PATH=\"\$HOME/bin:\$PATH\"\033[0m\n"
        fi
    fi





# ─────────────────────────────────────────
# Two-Phase Professional Workflow
# ─────────────────────────────────────────
# 🚀 DESIGN PHILOSOPHY: Separate testing from deployment
# PHASE 1: Comprehensive testing, linting, validation (can run repeatedly)
# PHASE 2: Version bump, build, commit, push (run once when ready to ship)
#
# 🔥 FAST-FAIL BEHAVIOR: Any error in any step stops the entire workflow
# WHY: Prevents cascading failures and wasted time on broken code
# HOW: bash -euo pipefail ensures any command failure stops execution
#
# 🔄 MINIMAL RECOMPILATION STRATEGY:
# • Clean build artifacts first (prevents cross-project contamination)
# • Use llvm-cov for both testing AND coverage (single compilation)
# • Run doc tests separately (avoids duplicate compilation)
# • Clippy reuses compilation artifacts from testing phase
# ─────────────────────────────────────────────────────────────────────────────

# PHASE 1: Code & Extensive Testing (Fast-Fail)
phase1-test:
    @printf "\033[0;34m🧪 PHASE 1: Code & Extensive Testing (FAST-FAIL)\033[0m\n"
    @printf "\033[1;33mRunning MOST extensive tests - STOPPING at FIRST failure...\033[0m\n"
    @echo "========================================================"
    @echo ""
    @printf "\033[0;34mStep 1: Cleaning build artifacts...\033[0m\n"
    cargo clean
    @printf "\033[0;32m✅ Build artifacts cleaned\033[0m\n"
    @printf "\033[0;34mStep 2: Auto-formatting code...\033[0m\n"
    cargo fmt --all
    @printf "\033[0;34mStep 3: Comprehensive compilation and validation (FAST-FAIL)...\033[0m\n"
    @printf "\033[0;34m  → Running unit & integration tests with coverage report (optimized)...\033[0m\n"
    @just _run-tests-with-coverage
    @printf "\033[0;32m✅ Unit & integration tests passed, coverage report generated\033[0m\n"
    @printf "\033[0;32m📁 Coverage report: target/llvm-cov/html/index.html\033[0m\n"
    @printf "\033[0;34m  → Running documentation tests only...\033[0m\n"
    cargo test --workspace --doc --all-features
    @printf "\033[0;32m✅ Documentation tests passed\033[0m\n"
    @just lint-prod
    @printf "\033[0;32m✅ Production code linting passed\033[0m\n"
    @just lint-tests
    @printf "\033[0;32m✅ Test code linting passed\033[0m\n"
    @printf "\033[0;34mStep 4: Final format validation (FAST-FAIL)...\033[0m\n"
    cargo fmt --all -- --check
    @echo ""
    @printf "\033[0;32m✅ PHASE 1 FAST-FAIL COMPLETE: All extensive tests passed, code ready for commit!\033[0m\n"
    @printf "\033[0;34m💡 Next: Run 'just phase2-ship' when ready to build/commit/push\033[0m\n"

# Helper recipe for test execution with coverage
_run-tests-with-coverage:
    #!/usr/bin/env bash
    if command -v cargo-nextest >/dev/null 2>&1; then
        printf "\033[0;34m    Using nextest for blazing-fast test execution...\033[0m\n"
        cargo llvm-cov nextest --workspace --all-features --html
    else
        printf "\033[1;33m    Using standard test runner...\033[0m\n"
        cargo llvm-cov test --workspace --all-features --all-targets --html
    fi

# PHASE 2: Version/Build/Deploy (Professional Grade)
phase2-ship:
    @printf "\033[0;34m🚀 PHASE 2: Version/Build/Deploy (Post-Testing)\033[0m\n"
    @printf "\033[1;33mAssumes Phase 1 completed: format ✅ clippy ✅ compile ✅ tests ✅\033[0m\n"
    @echo "========================================================"
    @echo ""
    @printf "\033[0;34mStep 1: Version increment...\033[0m\n"
    @just _version-increment
    @printf "\033[0;34mStep 2: Building release binary...\033[0m\n"
    cargo build --release
    @printf "\033[0;34mStep 3: Copy binary to deployment location...\033[0m\n"
    @just copy-binary release
    @printf "\033[0;34mStep 4: Adding all changes to staging area...\033[0m\n"
    git add .
    @printf "\033[0;34mStep 5: Creating auto-generated commit...\033[0m\n"
    @just _git-commit
    @printf "\033[0;34mStep 6: Syncing with remote and pushing...\033[0m\n"
    git pull origin main --rebase
    git push origin main
    @echo ""
    @printf "\033[0;32m✅ PHASE 2 COMPLETE: Version incremented, built, deployed, committed, and pushed!\033[0m\n"

# Helper recipe for version increment
_version-increment:
    #!/usr/bin/env bash
    if [ -f "./build/update_version.rs" ]; then
        ./build/update_version.rs patch
    else
        printf "\033[1;33m⚠️  Version script not found, skipping version increment\033[0m\n"
    fi

# Helper recipe for git commit
_git-commit:
    #!/usr/bin/env bash
    git commit -m "chore: release v$(grep '^version' Cargo.toml | head -1 | sed 's/.*\"\(.*\)\".*/\1/') - comprehensive testing complete [auto-commit]"

# Complete two-phase fast-fail workflow - perfect for rapid development
go:
    @printf "\033[0;34m🚀 Complete Two-Phase Fast-Fail Workflow\033[0m\n"
    @printf "\033[1;33mFailing fast at ANY error in either phase...\033[0m\n"
    @echo "========================================================"
    @echo ""
    @printf "\033[0;34m🧪 PHASE 1: Comprehensive Fast-Fail Testing & Validation\033[0m\n"
    @just phase1-test
    @echo ""
    @printf "\033[0;32m✅ PHASE 1 COMPLETE - All validation passed!\033[0m\n"
    @printf "\033[0;34m🚀 Starting PHASE 2: Build/Deploy...\033[0m\n"
    @echo ""
    @printf "\033[0;34m📦 PHASE 2: Fast-Fail Build & Deploy\033[0m\n"
    @just phase2-ship
    @echo ""
    @printf "\033[0;32m🎉 COMPLETE TWO-PHASE FAST-FAIL WORKFLOW FINISHED!\033[0m\n"
    @printf "\033[0;32m✅ Phase 1: Testing & Validation\033[0m\n"
    @printf "\033[0;32m✅ Phase 2: Build/Commit/Push/Deploy\033[0m\n"

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
    #!/usr/bin/env bash
    echo "\033[0;34m📋 Current version:\033[0m"
    grep '^version' Cargo.toml | head -1

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
# 🌍 CROSS-PLATFORM COMPATIBILITY STRATEGY:
# • Detect OS using $OSTYPE and $WINDIR environment variables
# • Use appropriate package managers: brew (macOS), apt/yum/pacman (Linux), choco (Windows)
# • Install Git Bash on Windows for consistent shell experience
# • Graceful fallbacks when package managers aren't available
#
# 🪟 WINDOWS SPECIFIC NOTES:
# • Requires Git for Windows for bash shell support
# • Uses Chocolatey for package management
# • PowerShell execution policy may need adjustment
# • Git Bash provides Unix-like environment on Windows
# ─────────────────────────────────────────────────────────────────────────────

setup-platform-tools:
    #!/usr/bin/env bash
    echo "🖥️  Checking platform-specific tools…"

    # PLATFORM DETECTION STRATEGY:
    # Uses $OSTYPE environment variable for primary detection
    # Falls back to $WINDIR for Windows detection in some environments
    # Each platform gets appropriate package manager and tool installation

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  → macOS detected"
        # Install Homebrew if missing (macOS package manager)
        command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Install essential tools via Homebrew
        command -v just >/dev/null || brew install just
        command -v git  >/dev/null || brew install git
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]] || [[ -n "$WINDIR" ]]; then
        echo "  → Windows detected (Git-Bash compatible)"
        # Install Chocolatey if missing (Windows package manager)
        # NOTE: PowerShell command executed from bash - requires careful escaping
        command -v choco >/dev/null || powershell -NoLogo -NoProfile -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        # Install essential tools via Chocolatey
        command -v just >/dev/null || choco install just -y
        command -v git  >/dev/null || choco install git  -y
        command -v where >/dev/null || choco install where -y  # Windows equivalent of 'which'
    else
        echo "  → Linux detected"
        # Handle different Linux package managers
        if command -v apt-get >/dev/null; then
            # Debian/Ubuntu family
            sudo apt-get update -qq && sudo apt-get install -y git curl build-essential
        elif command -v yum >/dev/null; then
            # RHEL/CentOS family
            sudo yum install -y git curl gcc
        elif command -v pacman >/dev/null; then
            # Arch Linux family
            sudo pacman -S --noconfirm git curl base-devel
        fi
        # Install just via cargo (most reliable on Linux)
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
    #!/usr/bin/env bash
    echo "\033[0;34m🏁 PERFORMANCE COMPARISON\033[0m"
    echo "\033[1;33mRunning both approaches for accurate measurement...\033[0m"
    echo ""
    echo "\033[0;34m=== APPROACH 1: Current (llvm-cov for all tests) ===\033[0m"
    just benchmark-current
    echo ""
    echo "\033[0;34m=== APPROACH 2: Separate (cargo test --doc) ===\033[0m"
    just benchmark-separate
    echo ""
    echo "\033[0;32m✅ Benchmark complete! Compare the times above.\033[0m"

# ═══════════════════════════════════════════════════════════════════════════════
# 🆘 TROUBLESHOOTING GUIDE & LEARNING RESOURCES
# ═══════════════════════════════════════════════════════════════════════════════
#
# This section provides solutions to common problems and resources for learning
# more about cross-platform build systems and Rust development workflows.
#
# 🚨 COMMON ISSUES & SOLUTIONS:
# ─────────────────────────────────────────────────────────────────────────────
#
# ISSUE: "just: command not found"
# SOLUTION: Install just command runner
#   • macOS: brew install just
#   • Windows: choco install just
#   • Linux: cargo install just --locked
#   • Or run: just setup-platform-tools
#
# ISSUE: Colors show as raw escape codes (e.g., \033[0;32m)
# SOLUTION: Terminal doesn't support ANSI colors
#   • Use a modern terminal (Windows Terminal, iTerm2, etc.)
#   • Or disable colors: NO_COLOR=1 just go
#   • Git Bash on Windows: Use Git Bash terminal, not PowerShell
#
# ISSUE: "bash: command not found" on Windows
# SOLUTION: Install Git for Windows (provides Git Bash)
#   • Download from: https://git-scm.com/download/win
#   • Or run: choco install git
#   • Alternative: Use PowerShell with limited functionality
#
# ISSUE: "cargo-nextest not found" or similar tool errors
# SOLUTION: Run setup to install all development tools
#   • just setup (installs all tools automatically)
#   • Or install individually: cargo install cargo-nextest
#
# ISSUE: Permission denied when copying binary
# SOLUTION: Ensure ~/bin directory is writable
#   • mkdir -p ~/bin
#   • Check permissions: ls -la ~/bin
#   • On Windows: Ensure not running as administrator
#
# ISSUE: Binary not found in PATH after installation
# SOLUTION: Add ~/bin to your PATH environment variable
#   • Run: just install (provides platform-specific guidance)
#   • Restart terminal after updating PATH
#   • Verify: echo $PATH | grep bin
#
# ISSUE: Fast-fail behavior not working (commands continue after errors)
# SOLUTION: Ensure bash strict mode is working
#   • Check shell setting: set shell := ["bash", "-euo", "pipefail", "-c"]
#   • Verify bash is available: which bash
#   • On Windows: Ensure Git Bash is installed
#
# ISSUE: Cross-platform path issues (Windows \ vs Unix /)
# SOLUTION: Use bash-compatible paths throughout
#   • All recipes use #!/usr/bin/env bash shebang
#   • Use forward slashes in paths
#   • Let bash handle path conversion on Windows
#
# 📚 LEARNING RESOURCES:
# ─────────────────────────────────────────────────────────────────────────────
#
# 🔧 JUSTFILE & BUILD SYSTEMS:
# • just documentation: https://just.systems/man/en/
# • Cross-platform scripting: https://github.com/casey/just/wiki
# • Build system patterns: https://github.com/casey/just/tree/master/examples
#
# 🦀 RUST DEVELOPMENT:
# • Rust Book: https://doc.rust-lang.org/book/
# • Cargo Book: https://doc.rust-lang.org/cargo/
# • Clippy lints: https://rust-lang.github.io/rust-clippy/master/
# • Testing guide: https://doc.rust-lang.org/book/ch11-00-testing.html
#
# 🖥️  CROSS-PLATFORM DEVELOPMENT:
# • Shell scripting: https://www.shellscript.sh/
# • Windows/Unix differences: https://github.com/microsoft/WSL/wiki
# • Git Bash guide: https://gitforwindows.org/
# • Terminal compatibility: https://github.com/microsoft/terminal
#
# 🎨 TERMINAL & COLORS:
# • ANSI escape codes: https://en.wikipedia.org/wiki/ANSI_escape_code
# • NO_COLOR standard: https://no-color.org/
# • Terminal feature detection: https://github.com/termstandard/colors
#
# 🔍 DEBUGGING TECHNIQUES:
# • Add 'set -x' to bash scripts for verbose output
# • Use 'just --dry-run' to see commands without executing
# • Check environment: 'env | grep -E "(OSTYPE|WINDIR|PATH)"'
# • Test individual recipes: 'just recipe-name'
#
# 💡 ADVANCED TOPICS:
# • Cargo workspaces: https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html
# • CI/CD integration: https://github.com/actions-rs
# • Security scanning: https://github.com/RustSec/rustsec
# • Performance profiling: https://github.com/flamegraph-rs/flamegraph
#
# 🤝 CONTRIBUTING TO THIS JUSTFILE:
# • Test changes on all platforms (Windows, macOS, Linux)
# • Document WHY, not just WHAT (explain design decisions)
# • Include examples of what fails without the fix
# • Update this troubleshooting section with new issues
# • Follow the educational philosophy: teach while implementing
#
# ═══════════════════════════════════════════════════════════════════════════════
