# 🚀 RUST MASTER: Bare Metal Windows PowerShell Setup
# This script installs everything needed for Rust development on Windows
#
# PREREQUISITES:
#   - Windows 10/11
#   - PowerShell 5.1+ (built into Windows)
#   - Administrator privileges
#   - Rust already installed (from https://rustup.rs/)
#
# USAGE:
#   1. Open PowerShell as Administrator
#   2. Navigate to the project directory
#   3. Run: .\setup-windows.ps1
#
# WHAT IT INSTALLS:
#   ✅ Chocolatey (Windows package manager)
#   ✅ Git for Windows (with Git Bash)
#   ✅ Just command runner
#   ✅ Complete Rust development toolchain (cargo tools)
#
# AFTER INSTALLATION:
#   1. Restart PowerShell
#   2. Add to your PowerShell profile:
#      function jb { just --shell 'C:\Program Files\Git\bin\bash.exe' @args }
#   3. Use 'jb setup' and 'jb go' for development

param(
    [switch]$Force,
    [switch]$SkipRustTools
)

# Enable ANSI colors in PowerShell
$PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::Ansi

Write-Host "$([char]27)[0;34m🚀 Rust Master: Bare Metal Windows Setup$([char]27)[0m"
Write-Host "$([char]27)[1;33mInstalling complete development environment from scratch$([char]27)[0m"
Write-Host ""

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Host "$([char]27)[1;31m❌ This script requires Administrator privileges$([char]27)[0m"
    Write-Host "$([char]27)[0;33m   Please run PowerShell as Administrator and try again$([char]27)[0m"
    exit 1
}

Write-Host "$([char]27)[0;32m✅ Running with Administrator privileges$([char]27)[0m"
Write-Host ""

# Step 1: Install Chocolatey
Write-Host "$([char]27)[0;34m📋 Step 1: Installing Chocolatey (Windows Package Manager)$([char]27)[0m"
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "$([char]27)[0;33m  → Installing Chocolatey...$([char]27)[0m"
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "$([char]27)[0;32m  ✅ Chocolatey installed successfully$([char]27)[0m"
    }
    catch {
        Write-Host "$([char]27)[1;31m  ❌ Failed to install Chocolatey: $($_.Exception.Message)$([char]27)[0m"
        exit 1
    }
} else {
    Write-Host "$([char]27)[0;32m  ✅ Chocolatey already installed$([char]27)[0m"
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host ""

# Step 2: Install Git for Windows
Write-Host "$([char]27)[0;34m📋 Step 2: Installing Git for Windows$([char]27)[0m"
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "$([char]27)[0;33m  → Installing Git for Windows...$([char]27)[0m"
    try {
        choco install git -y
        Write-Host "$([char]27)[0;32m  ✅ Git for Windows installed successfully$([char]27)[0m"
    }
    catch {
        Write-Host "$([char]27)[1;31m  ❌ Failed to install Git: $($_.Exception.Message)$([char]27)[0m"
        exit 1
    }
} else {
    Write-Host "$([char]27)[0;32m  ✅ Git already installed$([char]27)[0m"
}

Write-Host ""

# Step 3: Install Just Command Runner
Write-Host "$([char]27)[0;34m📋 Step 3: Installing Just Command Runner$([char]27)[0m"
if (!(Get-Command just -ErrorAction SilentlyContinue)) {
    Write-Host "$([char]27)[0;33m  → Installing just...$([char]27)[0m"
    try {
        choco install just -y
        Write-Host "$([char]27)[0;32m  ✅ Just command runner installed successfully$([char]27)[0m"
    }
    catch {
        Write-Host "$([char]27)[1;31m  ❌ Failed to install just: $($_.Exception.Message)$([char]27)[0m"
        exit 1
    }
} else {
    Write-Host "$([char]27)[0;32m  ✅ just already installed$([char]27)[0m"
}

# Refresh environment variables again
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host ""

# Step 4: Install Rust if not present
Write-Host "$([char]27)[0;34m📋 Step 4: Checking Rust Installation$([char]27)[0m"
if (!(Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "$([char]27)[0;33m  → Rust not found. Please install Rust first from https://rustup.rs/$([char]27)[0m"
    Write-Host "$([char]27)[0;33m  → Then run this script again$([char]27)[0m"
    exit 1
} else {
    $rustVersion = cargo --version
    Write-Host "$([char]27)[0;32m  ✅ Rust already installed: $rustVersion$([char]27)[0m"
}

Write-Host ""

# Step 5: Install Essential Rust Tools (if not skipped)
if (-not $SkipRustTools) {
    Write-Host "$([char]27)[0;34m📋 Step 5: Installing Essential Rust Tools$([char]27)[0m"
    Write-Host "$([char]27)[0;33m  → Installing core development tools...$([char]27)[0m"
    
    $tools = @(
        "cargo-binstall",
        "cargo-watch", 
        "cargo-nextest",
        "cargo-llvm-cov",
        "cargo-deny",
        "cargo-audit",
        "cargo-outdated",
        "cargo-udeps",
        "cargo-machete",
        "cargo-expand",
        "cargo-geiger",
        "cargo-criterion"
    )
    
    foreach ($tool in $tools) {
        try {
            Write-Host "$([char]27)[0;33m    → Installing $tool...$([char]27)[0m" -NoNewline
            $result = cargo install $tool --quiet 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$([char]27)[0;32m ✅$([char]27)[0m"
            } else {
                Write-Host "$([char]27)[1;33m ⚠️ (already installed or failed)$([char]27)[0m"
            }
        }
        catch {
            Write-Host "$([char]27)[1;33m ⚠️ (failed)$([char]27)[0m"
        }
    }
    
    Write-Host "$([char]27)[1;33m    ⚠️  Skipping cargo-semver-checks (known Windows compilation issues)$([char]27)[0m"
} else {
    Write-Host "$([char]27)[1;33m📋 Step 5: Skipping Rust tools installation (--SkipRustTools specified)$([char]27)[0m"
}

Write-Host ""

# Success message
Write-Host "$([char]27)[0;32m🎉 BARE METAL SETUP COMPLETE!$([char]27)[0m"
Write-Host "$([char]27)[0;32m✅ Chocolatey package manager$([char]27)[0m"
Write-Host "$([char]27)[0;32m✅ Git for Windows$([char]27)[0m"
Write-Host "$([char]27)[0;32m✅ Just command runner$([char]27)[0m"
if (-not $SkipRustTools) {
    Write-Host "$([char]27)[0;32m✅ Essential Rust development tools$([char]27)[0m"
}

Write-Host ""
Write-Host "$([char]27)[1;33m🚀 NEXT STEPS:$([char]27)[0m"
Write-Host "$([char]27)[0;33m  1. Restart PowerShell to refresh PATH$([char]27)[0m"
Write-Host "$([char]27)[0;33m  2. Add this to your PowerShell profile:$([char]27)[0m"
Write-Host "$([char]27)[0;36m     function jb { just --shell 'C:\Program Files\Git\bin\bash.exe' @args }$([char]27)[0m"
Write-Host "$([char]27)[0;33m  3. Use 'jb setup' for additional platform tools$([char]27)[0m"
Write-Host "$([char]27)[0;33m  4. Use 'jb go' to start developing$([char]27)[0m"
Write-Host ""
Write-Host "$([char]27)[0;34m💡 To edit your PowerShell profile:$([char]27)[0m"
Write-Host "$([char]27)[0;36m   notepad `$PROFILE$([char]27)[0m"
