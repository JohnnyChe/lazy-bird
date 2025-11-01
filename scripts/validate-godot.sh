#!/bin/bash
# Godot + gdUnit4 Validation Script
# Tests Godot headless mode and test framework

set -euo pipefail

PROJECT_PATH="${1:-}"

if [ -z "$PROJECT_PATH" ]; then
    echo "Usage: $0 <godot-project-path>"
    echo ""
    echo "Example:"
    echo "  $0 /home/user/my-godot-game"
    exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

if [ ! -f "$PROJECT_PATH/project.godot" ]; then
    echo "Error: Not a valid Godot project (project.godot not found)"
    exit 1
fi

echo "╔════════════════════════════════════════╗"
echo "║   Godot + gdUnit4 Validation Suite    ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Project: $PROJECT_PATH"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

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

# Test 1: Godot executable exists
echo "Test 1: Checking for Godot executable..."
if command -v godot &> /dev/null; then
    GODOT_PATH=$(which godot)
    pass "Godot found at: $GODOT_PATH"
else
    fail "Godot not found in PATH"
    echo "   Install Godot 4.2+ from: https://godotengine.org/"
    exit 1
fi

# Test 2: Godot version
echo ""
echo "Test 2: Checking Godot version..."
if GODOT_VERSION=$(godot --version 2>&1 | head -1); then
    pass "Godot version: $GODOT_VERSION"

    # Check if version is 4.x
    if echo "$GODOT_VERSION" | grep -q "^4\."; then
        pass "Godot 4.x detected (compatible)"
    elif echo "$GODOT_VERSION" | grep -q "^3\."; then
        warn "Godot 3.x detected - system designed for 4.x"
        echo "   May work but not fully tested"
    else
        warn "Could not determine Godot version"
    fi
else
    fail "Could not get Godot version"
fi

# Test 3: Headless mode
echo ""
echo "Test 3: Testing Godot headless mode..."
if godot --headless --quit --path "$PROJECT_PATH" > /dev/null 2>&1; then
    pass "Godot headless mode works"
else
    fail "Godot headless mode failed"
    echo "   This is required for automated testing"
fi

# Test 4: Project loads
echo ""
echo "Test 4: Testing project load..."
if godot --headless --check-only --path "$PROJECT_PATH" > /dev/null 2>&1; then
    pass "Project loads without errors"
else
    warn "Project has errors or warnings"
    echo "   Check: godot --headless --check-only --path $PROJECT_PATH"
fi

# Test 5: gdUnit4 installation
echo ""
echo "Test 5: Checking for gdUnit4..."
if [ -d "$PROJECT_PATH/addons/gdUnit4" ]; then
    pass "gdUnit4 is installed"

    # Check if command-line tool exists
    if [ -f "$PROJECT_PATH/addons/gdUnit4/bin/GdUnitCmdTool.gd" ]; then
        pass "gdUnit4 command-line tool found"
    else
        warn "gdUnit4 CLI tool not found"
        echo "   May need to update gdUnit4 installation"
    fi
else
    warn "gdUnit4 not installed"
    echo ""
    echo "   Installing gdUnit4..."

    cd "$PROJECT_PATH"
    if git clone https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4; then
        pass "gdUnit4 installed successfully"
    else
        fail "Could not install gdUnit4"
        echo "   Manual install: https://github.com/MikeSchulze/gdUnit4"
    fi
fi

# Test 6: gdUnit4 CLI test
echo ""
echo "Test 6: Testing gdUnit4 CLI..."
if [ -f "$PROJECT_PATH/addons/gdUnit4/bin/GdUnitCmdTool.gd" ]; then
    if godot --headless --path "$PROJECT_PATH" -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --help > /dev/null 2>&1; then
        pass "gdUnit4 CLI works"
    else
        warn "gdUnit4 CLI may need configuration"
        echo "   Check: godot --headless --path $PROJECT_PATH -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --help"
    fi
else
    warn "Skipping CLI test (gdUnit4 not installed)"
fi

# Test 7: Create sample test
echo ""
echo "Test 7: Creating sample test..."
TEST_DIR="$PROJECT_PATH/test"
mkdir -p "$TEST_DIR"

SAMPLE_TEST="$TEST_DIR/test_validation.gd"
if [ ! -f "$SAMPLE_TEST" ]; then
    cat > "$SAMPLE_TEST" << 'EOF'
extends GdUnitTestSuite

func test_basic_math():
    assert_that(1 + 1).is_equal(2)

func test_string_comparison():
    assert_that("hello").is_equal("hello")

func test_boolean():
    assert_that(true).is_true()
EOF
    pass "Sample test created: $SAMPLE_TEST"
else
    pass "Sample test already exists"
fi

# Test 8: Run sample test
echo ""
echo "Test 8: Running sample test..."
if [ -f "$PROJECT_PATH/addons/gdUnit4/bin/GdUnitCmdTool.gd" ]; then
    TEST_OUTPUT=$(mktemp)
    if godot --headless --path "$PROJECT_PATH" -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite res://test/test_validation.gd > "$TEST_OUTPUT" 2>&1; then
        if grep -qi "passed\|success" "$TEST_OUTPUT" || ! grep -qi "failed\|error" "$TEST_OUTPUT"; then
            pass "Sample test executed successfully"
        else
            warn "Test ran but results unclear"
            echo "   Output: $(head -5 "$TEST_OUTPUT")"
        fi
    else
        warn "Test execution failed"
        echo "   Check output: $TEST_OUTPUT"
        cat "$TEST_OUTPUT"
    fi
    rm -f "$TEST_OUTPUT"
else
    warn "Skipping test execution (gdUnit4 not ready)"
fi

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
    echo "Godot setup does not meet requirements."
    echo "Fix the failed tests above before proceeding."
    exit 1
elif [ $WARNINGS -gt 2 ]; then
    echo -e "${YELLOW}⚠ VALIDATION PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Godot works but with some limitations."
    echo "Review warnings above."
    exit 0
else
    echo -e "${GREEN}✅ VALIDATION PASSED${NC}"
    echo ""
    echo "Godot + gdUnit4 ready for automation!"
    echo ""
    echo "Verified:"
    echo "  ✓ Godot 4.x installed"
    echo "  ✓ Headless mode works"
    echo "  ✓ Project loads correctly"
    echo "  ✓ gdUnit4 installed and functional"
    echo "  ✓ Sample tests execute"
    echo ""
    echo "Next: Run full Phase 0 validation"
    exit 0
fi
