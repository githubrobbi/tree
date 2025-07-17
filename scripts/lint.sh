#!/bin/bash
# Rust Master Linting Script
# Usage: ./scripts/lint.sh [production|tests|all]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Common clippy flags
COMMON_FLAGS="-D clippy::pedantic -D clippy::nursery -D clippy::cargo -A clippy::multiple_crate_versions -W clippy::panic -W clippy::todo -W clippy::unimplemented -D warnings"

# Production-specific flags (strict unwrap/expect)
PRODUCTION_FLAGS="$COMMON_FLAGS -W clippy::unwrap_used -W clippy::expect_used -W clippy::missing_docs_in_private_items"

# Test-specific flags (allow unwrap/expect)
TEST_FLAGS="$COMMON_FLAGS -A clippy::unwrap_used -A clippy::expect_used"

lint_production() {
    echo -e "${BLUE}🔍 Linting production code (ultra-strict)...${NC}"
    cargo clippy --lib --bins -- $PRODUCTION_FLAGS
    echo -e "${GREEN}✅ Production code passes all checks!${NC}"
}

lint_tests() {
    echo -e "${BLUE}🧪 Linting test code (pragmatic)...${NC}"
    cargo clippy --tests -- $TEST_FLAGS
    echo -e "${GREEN}✅ Test code passes all checks!${NC}"
}

lint_all() {
    echo -e "${BLUE}🌍 Linting all code (mixed approach)...${NC}"
    cargo clippy --workspace --all-targets --all-features -- $TEST_FLAGS
    echo -e "${GREEN}✅ All code passes checks!${NC}"
}

case "${1:-all}" in
    "production"|"prod"|"lib")
        lint_production
        ;;
    "tests"|"test")
        lint_tests
        ;;
    "all"|"")
        lint_all
        ;;
    *)
        echo -e "${RED}❌ Usage: $0 [production|tests|all]${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}💡 Tip: Use 'cargo clippy --fix' to auto-fix issues${NC}"
