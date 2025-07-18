# Tree - Modern Rust Development Workflow
# Professional CLI tree utility with intelligent ignore patterns
# Cross-platform compatible - works on Windows, macOS, and Linux

# Export color environment variables for Git Bash
export FORCE_COLOR := "1"
export CLICOLOR_FORCE := "1"
export TERM := "xterm-256color"
export COLORTERM := "truecolor"
export CARGO_TERM_COLOR := "always"

# Colors for output - cross-platform compatible
# Use bash-style escapes by default (works in Git Bash, Unix, macOS)
# PowerShell users should use 'just setup-powershell' for colors
GREEN := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0;32m' }
BLUE := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0;34m' }
YELLOW := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[1;33m' }
RED := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0;31m' }
NC := if env_var_or_default("NO_COLOR", "") == "1" { "" } else { '\033[0m' }

# Default recipe - show available commands
default:
    @echo "=== ANSI Color Testing in Git Bash + PowerShell ==="
    @echo ""
    @echo "1. Basic echo with justfile variables:"
    @echo "{{BLUE}}🌳 Tree - Modern Rust Development Workflow{{NC}}"
    @echo ""
    @echo "2. Raw echo with escape sequences:"
    @echo "\033[0;34m🌳 Raw escape sequence\033[0m"
    @echo ""
    @echo "3. Echo with -e flag:"
    echo -e "\033[0;32m🌳 Echo with -e flag\033[0m"
    @echo ""
    @echo "4. Printf approach:"
    printf "\033[0;31m🌳 Printf approach\033[0m\n"
    @echo ""
    @echo "5. PowerShell style (should fail in bash):"
    @echo "$([char]27)[38;2;255;105;180m🌳 PowerShell style$([char]27)[0m"
    @echo ""
    @echo "6. Bash script approach:"
    just test-bash-colors
    @echo ""
    @echo "7. Different escape formats:"
    just test-escape-formats

# Test bash colors with a script
test-bash-colors:
    #!/usr/bin/env bash
    echo -e "\033[0;35m🌳 Bash script with echo -e\033[0m"
    printf "\033[0;36m🌳 Bash script with printf\033[0m\n"

# Test different escape sequence formats
test-escape-formats:
    @echo "Testing different escape formats:"
    @echo "\\033 format: \033[0;33mYellow\033[0m"
    @echo "\\e format: \e[0;33mYellow\e[0m"
    @echo "\\x1b format: \x1b[0;33mYellow\x1b[0m"
    echo -e "echo -e \\033: \033[0;33mYellow\033[0m"
    echo -e "echo -e \\e: \e[0;33mYellow\e[0m"
    echo -e "echo -e \\x1b: \x1b[0;33mYellow\x1b[0m"

# PowerShell specific test
test-powershell:
    Write-Host "$([char]27)[38;2;255;105;180mPowerShell TRUECOLOR$([char]27)[0m"
    Write-Host "$([char]27)[0;32mPowerShell Green$([char]27)[0m"
    Write-Host "$([char]27)[0;34mPowerShell Blue$([char]27)[0m"

# Test with environment variables
test-env:
    @echo "TERM: $TERM"
    @echo "COLORTERM: $COLORTERM"
    @echo "FORCE_COLOR: $FORCE_COLOR"
    @echo "NO_COLOR: $NO_COLOR"
    @echo "SHELL: $SHELL"
    @echo "OS: {{os()}}"

# Test tput approach (terminal capability database)
test-tput:
    @echo "Testing tput approach:"
    @tput setaf 1 && echo "Red with tput" && tput sgr0
    @tput setaf 2 && echo "Green with tput" && tput sgr0
    @tput setaf 4 && echo "Blue with tput" && tput sgr0

# Test with different shells explicitly
test-shells:
    @echo "Testing with different shell approaches:"
    @echo "Current shell: $0"
    bash -c 'echo -e "\033[0;32mBash explicit call\033[0m"'
    sh -c 'echo "\033[0;31mSh explicit call\033[0m"'

# Test with cat and here documents
test-cat:
    @echo "Testing with cat:"
    @cat << 'EOF'
	\033[0;35mCat with here document\033[0m
	EOF

# Test with different justfile approaches
test-justfile-methods:
    @echo "Testing justfile-specific methods:"
    @echo "Method 1 - Direct variable: {{BLUE}}Blue{{NC}}"
    @echo 'Method 2 - Single quotes: \033[0;32mGreen\033[0m'
    @echo "Method 3 - Double quotes: \033[0;31mRed\033[0m"
    echo 'Method 4 - No @ prefix: \033[0;33mYellow\033[0m'

# Test comprehensive approach
test-all:
    @echo "Running all color tests..."
    just default
    just test-env
    just test-tput
    just test-shells
    just test-cat
    just test-justfile-methods
