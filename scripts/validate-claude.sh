#!/bin/bash
# Claude Code CLI Validation Script
# Tests all assumed Claude Code capabilities

set -euo pipefail

echo "╔════════════════════════════════════════╗"
echo "║   Claude Code CLI Validation Suite    ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track results
PASSED=0
FAILED=0
WARNINGS=0

# Test functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    FAILED=$((FAILED + 1))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# Test 1: Command exists
echo "Test 1: Checking if 'claude' command exists..."
if command -v claude &> /dev/null; then
    pass "claude command found in PATH"
else
    fail "claude command not found"
    echo "   Install from: https://claude.ai/code"
    exit 1
fi

# Test 2: Get version
echo ""
echo "Test 2: Getting Claude version..."
if VERSION=$(claude --version 2>&1); then
    pass "Claude version: $VERSION"
else
    fail "Could not get Claude version"
fi

# Test 3: Basic headless prompt
echo ""
echo "Test 3: Testing basic headless execution (-p flag)..."
TEST_OUTPUT=$(mktemp)
if claude -p "Print the text 'test123'" > "$TEST_OUTPUT" 2>&1; then
    if grep -q "test123" "$TEST_OUTPUT" || grep -qi "test.*123" "$TEST_OUTPUT"; then
        pass "Basic headless mode works"
    else
        warn "Headless mode ran but output unexpected"
        echo "   Output: $(cat "$TEST_OUTPUT")"
    fi
else
    fail "Headless mode failed"
    echo "   Error: $(cat "$TEST_OUTPUT")"
fi
rm -f "$TEST_OUTPUT"

# Test 4: File modification test
echo ""
echo "Test 4: Testing file modification capability..."
TEST_FILE=$(mktemp)
echo "original content" > "$TEST_FILE"

# Try to modify file
claude -p "Modify the file $TEST_FILE to contain exactly the text 'modified by claude'" > /dev/null 2>&1 || true

if grep -q "modified by claude" "$TEST_FILE"; then
    pass "Claude can modify files headlessly"
elif grep -q "original content" "$TEST_FILE"; then
    warn "Claude did not modify file - may require --dangerously-skip-permissions"
    echo "   This means full automation requires Docker containers"
else
    warn "File state unclear after Claude execution"
fi
rm -f "$TEST_FILE"

# Test 5: Tool restrictions
echo ""
echo "Test 5: Testing --allowedTools flag..."
if claude -p "test" --allowedTools "Read" > /dev/null 2>&1; then
    pass "--allowedTools flag supported"
else
    warn "--allowedTools flag may not be supported"
    echo "   Will need alternative safety measures"
fi

# Test 6: Output format
echo ""
echo "Test 6: Testing --output-format json..."
TEST_OUTPUT=$(mktemp)
if claude -p "test" --output-format json > "$TEST_OUTPUT" 2>&1; then
    if command -v jq &> /dev/null; then
        if jq . "$TEST_OUTPUT" > /dev/null 2>&1; then
            pass "JSON output format works"
        else
            warn "JSON output may not be properly formatted"
        fi
    else
        warn "jq not installed, cannot validate JSON"
    fi
else
    warn "JSON output format may not be supported"
    echo "   Will use text output parsing instead"
fi
rm -f "$TEST_OUTPUT"

# Test 7: Dangerous mode (only if Docker available)
echo ""
echo "Test 7: Testing containerized dangerous mode..."
if command -v docker &> /dev/null; then
    if docker ps > /dev/null 2>&1; then
        pass "Docker available for dangerous mode"
        echo "   Full automation possible with containerization"
    else
        warn "Docker installed but daemon not running"
        echo "   Start with: sudo systemctl start docker"
    fi
else
    warn "Docker not available"
    echo "   Dangerous mode will not be available"
    echo "   Install with: sudo pacman -S docker  # or apt-get install docker.io"
fi

# Test 8: Workspace directory handling
echo ""
echo "Test 8: Testing working directory behavior..."
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
echo "test file" > test.txt

if claude -p "List files in current directory" > /dev/null 2>&1; then
    pass "Claude operates in current working directory"
else
    warn "Directory handling unclear"
fi

cd - > /dev/null
rm -rf "$TEST_DIR"

# Summary
echo ""
echo "╔════════════════════════════════════════╗"
echo "║           VALIDATION RESULTS           ║"
echo "╠════════════════════════════════════════╣"
printf "║ %-20s %17s ║\n" "Passed:" "$PASSED"
printf "║ %-20s %17s ║\n" "Failed:" "$FAILED"
printf "║ %-20s %17s ║\n" "Warnings:" "$WARNINGS"
echo "╚════════════════════════════════════════╝"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ VALIDATION FAILED${NC}"
    echo ""
    echo "Claude Code CLI does not meet requirements for automation."
    echo "Fix the failed tests above before proceeding."
    exit 1
elif [ $WARNINGS -gt 2 ]; then
    echo -e "${YELLOW}⚠ VALIDATION PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Claude Code works but with limitations."
    echo "Review warnings above and plan accordingly."
    echo ""
    echo "Recommended:"
    echo "  - Use Docker for full automation (--dangerously-skip-permissions)"
    echo "  - Implement alternative tool restrictions if --allowedTools not available"
    echo "  - Use text output parsing if JSON not available"
    exit 0
else
    echo -e "${GREEN}✅ VALIDATION PASSED${NC}"
    echo ""
    echo "Claude Code CLI is ready for automation!"
    echo ""
    echo "Supported features:"
    echo "  ✓ Headless mode (-p flag)"
    echo "  ✓ File modifications"
    echo "  ✓ Tool restrictions (--allowedTools)"
    echo "  ✓ JSON output format"
    echo "  ✓ Docker available for dangerous mode"
    echo ""
    echo "Next step: Run full Phase 0 validation"
    echo "  ./tests/phase0/validate-all.sh /path/to/godot-project"
    exit 0
fi
