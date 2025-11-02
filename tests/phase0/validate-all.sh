#!/bin/bash
# Phase 0: Complete Validation Suite
# Master script that runs all Phase 0 validation tests

set -euo pipefail

echo "╔════════════════════════════════════════╗"
echo "║  Phase 0: Complete Validation Suite   ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Parse arguments
PROJECT_PATH=""
FRAMEWORK_TYPE="godot"  # Default for backward compatibility

while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            FRAMEWORK_TYPE="$2"
            shift 2
            ;;
        *)
            PROJECT_PATH="$1"
            shift
            ;;
    esac
done

if [ -z "$PROJECT_PATH" ]; then
    echo "Usage: $0 <project-path> [--type <framework>]"
    echo ""
    echo "Arguments:"
    echo "  project-path    Path to your project directory"
    echo "  --type          Framework type (default: godot)"
    echo ""
    echo "Supported framework types:"
    echo "  godot, python, rust, nodejs, django, react, custom"
    echo ""
    echo "Examples:"
    echo "  $0 /home/user/my-godot-game"
    echo "  $0 /home/user/my-python-app --type python"
    echo "  $0 /home/user/my-rust-cli --type rust"
    echo ""
    echo "This script runs all Phase 0 validation tests:"
    echo "  1. Claude Code CLI validation (universal)"
    echo "  2. Framework-specific validation (based on --type)"
    echo "  3. Git worktree validation (universal)"
    exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

# Get absolute path to scripts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_PATH="$SCRIPT_DIR/scripts"

# Verify scripts exist
if [ ! -f "$SCRIPTS_PATH/validate-claude.sh" ]; then
    echo "Error: validate-claude.sh not found at $SCRIPTS_PATH/validate-claude.sh"
    exit 1
fi

if [ ! -f "$SCRIPTS_PATH/validate-godot.sh" ]; then
    echo "Error: validate-godot.sh not found at $SCRIPTS_PATH/validate-godot.sh"
    exit 1
fi

if [ ! -f "$SCRIPTS_PATH/test-worktree.sh" ]; then
    echo "Error: test-worktree.sh not found at $SCRIPTS_PATH/test-worktree.sh"
    exit 1
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Track individual script results
CLAUDE_RESULT=0
FRAMEWORK_RESULT=0
WORKTREE_RESULT=0

# Framework validation functions
validate_godot() {
    echo "Validating Godot + gdUnit4..."
    if [ -f "$SCRIPTS_PATH/validate-godot.sh" ]; then
        "$SCRIPTS_PATH/validate-godot.sh" "$PROJECT_PATH"
        return $?
    else
        echo "❌ validate-godot.sh not found"
        return 1
    fi
}

validate_python() {
    echo "Validating Python environment..."

    # Check python3
    if ! command -v python3 &> /dev/null; then
        echo "❌ python3 not found"
        echo "   Install: sudo apt-get install python3  # or pacman -S python"
        return 1
    fi
    echo "✓ python3 found: $(python3 --version)"

    # Check pip3
    if ! command -v pip3 &> /dev/null; then
        echo "❌ pip3 not found"
        echo "   Install: sudo apt-get install python3-pip"
        return 1
    fi
    echo "✓ pip3 found"

    # Check for pytest (optional but recommended)
    if python3 -c "import pytest" 2>/dev/null; then
        echo "✓ pytest installed"
    else
        echo "⚠️  pytest not installed (optional, but recommended for testing)"
        echo "   Install: pip3 install pytest"
    fi

    echo "✅ Python environment validated"
    return 0
}

validate_rust() {
    echo "Validating Rust environment..."

    # Check cargo
    if ! command -v cargo &> /dev/null; then
        echo "❌ cargo not found"
        echo "   Install: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return 1
    fi
    echo "✓ cargo found: $(cargo --version)"

    # Check rustc
    if ! command -v rustc &> /dev/null; then
        echo "❌ rustc not found"
        return 1
    fi
    echo "✓ rustc found: $(rustc --version)"

    # Check for Cargo.toml in project
    if [ -f "$PROJECT_PATH/Cargo.toml" ]; then
        echo "✓ Cargo.toml found in project"
    else
        echo "❌ Cargo.toml not found in $PROJECT_PATH"
        echo "   This doesn't appear to be a Rust project"
        return 1
    fi

    echo "✅ Rust environment validated"
    return 0
}

validate_nodejs() {
    echo "Validating Node.js environment..."

    # Check node
    if ! command -v node &> /dev/null; then
        echo "❌ node not found"
        echo "   Install: sudo apt-get install nodejs  # or pacman -S nodejs"
        return 1
    fi
    echo "✓ node found: $(node --version)"

    # Check npm
    if ! command -v npm &> /dev/null; then
        echo "❌ npm not found"
        echo "   Install: sudo apt-get install npm"
        return 1
    fi
    echo "✓ npm found: $(npm --version)"

    # Check for package.json in project
    if [ -f "$PROJECT_PATH/package.json" ]; then
        echo "✓ package.json found in project"
    else
        echo "❌ package.json not found in $PROJECT_PATH"
        echo "   This doesn't appear to be a Node.js project"
        return 1
    fi

    echo "✅ Node.js environment validated"
    return 0
}

validate_framework() {
    local framework_type="${1:-godot}"

    case "$framework_type" in
        godot)
            validate_godot
            ;;
        python|django|flask|fastapi)
            validate_python
            ;;
        rust|bevy)
            validate_rust
            ;;
        nodejs|react|vue|angular|svelte|express)
            validate_nodejs
            ;;
        custom)
            echo "Custom project type - skipping framework validation"
            echo "✅ Custom validation (no framework-specific checks)"
            return 0
            ;;
        *)
            echo "⚠️  Unknown framework type: $framework_type"
            echo "   Skipping framework-specific validation"
            return 0
            ;;
    esac
}

echo "Project: $PROJECT_PATH"
echo "Framework: $FRAMEWORK_TYPE"
echo ""
echo "Running validation scripts..."
echo "════════════════════════════════════════"
echo ""

# Test 1: Claude Code Validation
echo -e "${BLUE}[1/3]${NC} Claude Code CLI Validation"
echo "────────────────────────────────────────"
TESTS_RUN=$((TESTS_RUN + 1))

if "$SCRIPTS_PATH/validate-claude.sh"; then
    CLAUDE_RESULT=0
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✅ PASSED${NC} - Claude Code validation successful"
else
    CLAUDE_RESULT=$?
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}❌ FAILED${NC} - Claude Code validation failed"
fi

echo ""
echo ""

# Test 2: Framework Validation
FRAMEWORK_NAME=$(echo "$FRAMEWORK_TYPE" | tr '[:lower:]' '[:upper:]')
echo -e "${BLUE}[2/3]${NC} Framework Validation ($FRAMEWORK_NAME)"
echo "────────────────────────────────────────"
TESTS_RUN=$((TESTS_RUN + 1))

if validate_framework "$FRAMEWORK_TYPE"; then
    FRAMEWORK_RESULT=0
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✅ PASSED${NC} - $FRAMEWORK_NAME validation successful"
else
    FRAMEWORK_RESULT=$?
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}❌ FAILED${NC} - $FRAMEWORK_NAME validation failed"
fi

echo ""
echo ""

# Test 3: Git Worktree Validation
echo -e "${BLUE}[3/3]${NC} Git Worktree Validation"
echo "────────────────────────────────────────"
TESTS_RUN=$((TESTS_RUN + 1))

if "$SCRIPTS_PATH/test-worktree.sh" "$PROJECT_PATH"; then
    WORKTREE_RESULT=0
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✅ PASSED${NC} - Worktree validation successful"
else
    WORKTREE_RESULT=$?
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}❌ FAILED${NC} - Worktree validation failed"
fi

echo ""
echo ""

# Final Summary
echo "╔════════════════════════════════════════╗"
echo "║      PHASE 0 VALIDATION SUMMARY        ║"
echo "╠════════════════════════════════════════╣"
printf "║ %-20s %17s ║\n" "Tests Run:" "$TESTS_RUN"
printf "║ %-20s %17s ║\n" "Passed:" "$TESTS_PASSED"
printf "║ %-20s %17s ║\n" "Failed:" "$TESTS_FAILED"
echo "╠════════════════════════════════════════╣"

# Individual results
if [ $CLAUDE_RESULT -eq 0 ]; then
    printf "║ %-20s %17s ║\n" "Claude Code:" "✓ PASS"
else
    printf "║ %-20s %17s ║\n" "Claude Code:" "✗ FAIL"
fi

FRAMEWORK_LABEL="$FRAMEWORK_NAME:"
if [ $FRAMEWORK_RESULT -eq 0 ]; then
    printf "║ %-20s %17s ║\n" "$FRAMEWORK_LABEL" "✓ PASS"
else
    printf "║ %-20s %17s ║\n" "$FRAMEWORK_LABEL" "✗ FAIL"
fi

if [ $WORKTREE_RESULT -eq 0 ]; then
    printf "║ %-20s %17s ║\n" "Git Worktrees:" "✓ PASS"
else
    printf "║ %-20s %17s ║\n" "Git Worktrees:" "✗ FAIL"
fi

echo "╚════════════════════════════════════════╝"
echo ""

# Final verdict
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL PHASE 0 VALIDATIONS PASSED  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    echo "Your system is ready for Lazy_Bird automation!"
    echo ""
    echo "Verified:"
    echo "  ✓ Claude Code CLI (8 tests)"
    echo "  ✓ $FRAMEWORK_NAME framework"
    echo "  ✓ Git worktrees for multi-agent"
    echo ""
    echo "Next Steps:"
    echo "  1. Run the setup wizard: ./wizard.sh"
    echo "  2. Create your first issue with 'ready' label"
    echo "  3. Watch Lazy_Bird automate your development workflow!"
    echo ""
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════╗${NC}"
    echo -e "${RED}║    ❌ PHASE 0 VALIDATION FAILED      ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════╝${NC}"
    echo ""
    echo "Failed: $TESTS_FAILED/$TESTS_RUN validation script(s)"
    echo ""
    echo "Please fix the failures above before proceeding."
    echo "Review the error messages and consult documentation:"
    echo "  - Docs/Design/phase0-validation.md"
    echo "  - Docs/Design/claude-cli-reference.md"
    echo ""
    exit 1
fi
