#!/bin/bash
#
# Git Commit Validation Hook
#
# This hook runs before Bash tool execution and validates
# git commit commands to ensure test coverage requirements are met.
#

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Read the command from stdin (tool_input)
COMMAND=$(cat | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only validate git commit commands
if [[ ! "$COMMAND" =~ git[[:space:]]+commit ]]; then
    exit 0
fi

cd "$PROJECT_DIR"

echo "Validating commit for test coverage..." >&2

# Get staged files
STAGED=$(git diff --cached --name-only 2>/dev/null || true)

if [[ -z "$STAGED" ]]; then
    exit 0
fi

# Count code files vs test files
CODE_FILES=$(echo "$STAGED" | grep -E '\.(go|ts|tsx|js|jsx)$' | grep -vE '_test\.|\.spec\.|__tests__' | wc -l | tr -d ' ')
TEST_FILES=$(echo "$STAGED" | grep -E '(_test\.(go|ts|tsx|js)|\.spec\.(ts|tsx|js))$' | wc -l | tr -d ' ')

# Check for critical files without tests
CRITICAL_FILES=$(echo "$STAGED" | grep -E '(license|stripe|payment|checkout|billing|auth)' | grep -vE '_test\.|\.spec\.' | head -5)

if [[ -n "$CRITICAL_FILES" ]] && [[ "$TEST_FILES" -eq 0 ]]; then
    echo "Critical business files staged without tests:" >&2
    echo "$CRITICAL_FILES" | head -5 >&2

    cat <<EOF
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "TDD Requirement: Critical business files (license, payment, auth) require tests. Please add tests before committing."
}
EOF
    exit 0
fi

# Warn if code files without any test files
if [[ "$CODE_FILES" -gt 0 ]] && [[ "$TEST_FILES" -eq 0 ]]; then
    echo "Warning: $CODE_FILES code file(s) staged without test files." >&2
    # Allow but warn - non-critical files can proceed
fi

exit 0
