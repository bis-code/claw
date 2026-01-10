#!/usr/bin/env bash
#
# feedback.sh - Test runner and error parser for claw
# Part of the TDD-driven autonomous execution system
#

set -euo pipefail

TEST_OUTPUT_FILE=".claude/test-output.log"
BUILD_OUTPUT_FILE=".claude/build-output.log"

# ============================================================================
# Test Detection
# ============================================================================

# Detect the test framework used in the project
# Usage: detect_test_framework
detect_test_framework() {
    if [[ -f "package.json" ]]; then
        if command -v jq &>/dev/null && jq -e '.scripts.test' package.json &>/dev/null; then
            echo "npm"
            return 0
        fi
    fi

    if [[ -f "pyproject.toml" ]] || [[ -f "pytest.ini" ]] || [[ -f "setup.py" ]]; then
        if grep -q "pytest" pyproject.toml 2>/dev/null || [[ -f "pytest.ini" ]]; then
            echo "pytest"
            return 0
        fi
    fi

    if [[ -f "Cargo.toml" ]]; then
        echo "cargo"
        return 0
    fi

    if [[ -f "go.mod" ]]; then
        echo "go"
        return 0
    fi

    echo "unknown"
}

# ============================================================================
# Test Execution
# ============================================================================

# Run tests using the detected framework
# Usage: run_tests [--capture]
run_tests() {
    local capture=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --capture)
                capture=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local framework
    framework=$(detect_test_framework)

    local cmd=""
    case "$framework" in
        npm)
            cmd="npm test"
            ;;
        pytest)
            cmd="pytest"
            ;;
        cargo)
            cmd="cargo test"
            ;;
        go)
            cmd="go test ./..."
            ;;
        *)
            echo "Unknown test framework"
            return 1
            ;;
    esac

    if $capture; then
        mkdir -p .claude
        set +e
        $cmd 2>&1 | tee "$TEST_OUTPUT_FILE"
        local exit_code=${PIPESTATUS[0]}
        set -e
        return $exit_code
    else
        $cmd
    fi
}

# ============================================================================
# Error Parsing
# ============================================================================

# Parse test errors from output
# Usage: parse_test_errors "file" [--json]
parse_test_errors() {
    local file="$1"
    local json_output=false

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                json_output=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi

    local content
    content=$(cat "$file")

    # Try to parse pytest errors first (more specific match)
    if echo "$content" | grep -q "FAILED.*::"; then
        _parse_pytest_errors "$file" "$json_output"
        return 0
    fi

    # Try to parse Jest/JavaScript errors
    if echo "$content" | grep -q "FAIL \|● "; then
        _parse_jest_errors "$file" "$json_output"
        return 0
    fi

    # Generic parsing
    if $json_output; then
        echo '{"errors": []}'
    else
        echo "No parseable errors found"
    fi
}

# Internal: Parse Jest errors
_parse_jest_errors() {
    local file="$1"
    local json_output="$2"

    local test_file=""
    local line_num=""
    local error_msg=""

    # Extract file and line from Jest output
    while IFS= read -r line; do
        if [[ "$line" =~ FAIL[[:space:]]+(.+) ]]; then
            test_file="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ at[[:space:]].*\(([^:]+):([0-9]+): ]]; then
            test_file="${BASH_REMATCH[1]}"
            line_num="${BASH_REMATCH[2]}"
        elif [[ "$line" == *"Expected:"* ]] || [[ "$line" == *"Received:"* ]]; then
            error_msg="$error_msg $line"
        fi
    done < "$file"

    if $json_output; then
        jq -n \
            --arg file "$test_file" \
            --arg line "$line_num" \
            --arg error "$error_msg" \
            '{file: $file, line: $line, error: $error}'
    else
        echo "File: $test_file"
        [[ -n "$line_num" ]] && echo "Line: line $line_num"
        [[ -n "$error_msg" ]] && echo "Error:$error_msg"
    fi
}

# Internal: Parse pytest errors
_parse_pytest_errors() {
    local file="$1"
    local json_output="$2"

    local test_file=""
    local test_name=""
    local error_msg=""

    while IFS= read -r line; do
        # Match: FAILED tests/test_utils.py::test_add - AssertionError
        if [[ "$line" == FAILED* ]]; then
            # Extract: remove "FAILED ", split on "::", take first two parts
            local stripped="${line#FAILED }"
            # Split on ::
            if [[ "$stripped" == *"::"* ]]; then
                test_file="${stripped%%::*}"
                local rest="${stripped#*::}"
                test_name="${rest%% *}"  # Take first word after ::
            fi
        elif [[ "$line" == *"assert"* ]]; then
            error_msg="$line"
        fi
    done < "$file"

    if $json_output; then
        jq -n \
            --arg file "$test_file" \
            --arg test "$test_name" \
            --arg error "$error_msg" \
            '{file: $file, test: $test, error: $error}'
    else
        echo "File: $test_file"
        [[ -n "$test_name" ]] && echo "Test: $test_name"
        [[ -n "$error_msg" ]] && echo "Error: $error_msg"
    fi
}

# ============================================================================
# Fix Suggestions
# ============================================================================

# Suggest a fix for a common error
# Usage: suggest_fix "error_message"
suggest_fix() {
    local error="$1"

    if [[ "$error" =~ Cannot\ read\ property|undefined|null ]]; then
        echo "Suggestion: Add a null check before accessing the property"
    elif [[ "$error" =~ Expected.*received|Expected.*but.*got|assert.*== ]]; then
        echo "Suggestion: Check the return value of the function under test"
    elif [[ "$error" =~ import|require|module ]]; then
        echo "Suggestion: Check that the module is installed and the import path is correct"
    elif [[ "$error" =~ TypeError|type.*mismatch ]]; then
        echo "Suggestion: Check the types of arguments being passed"
    else
        echo "Suggestion: Review the error message and check the relevant code"
    fi
}

# ============================================================================
# Feedback Loop
# ============================================================================

# Run a command with retries
# Usage: feedback_loop "command" [--max-retries N]
feedback_loop() {
    local cmd="$1"
    local max_retries=3

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max-retries)
                max_retries="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    local attempt=0
    while [[ $attempt -lt $max_retries ]]; do
        ((attempt++)) || true

        set +e
        local output
        output=$($cmd 2>&1)
        local exit_code=$?
        set -e

        echo "$output"

        if [[ $exit_code -eq 0 ]]; then
            return 0
        fi

        if [[ $attempt -lt $max_retries ]]; then
            echo "Retry $attempt of $max_retries..."
        else
            echo "Retry $attempt of $max_retries..."
            echo "Max retries exceeded"
            return 1
        fi
    done

    return 1
}

# ============================================================================
# Build Detection
# ============================================================================

# Detect the build command for the project
# Usage: detect_build_command
detect_build_command() {
    if [[ -f "package.json" ]]; then
        if command -v jq &>/dev/null && jq -e '.scripts.build' package.json &>/dev/null; then
            echo "npm run build"
            return 0
        fi
    fi

    if [[ -f "Cargo.toml" ]]; then
        echo "cargo build"
        return 0
    fi

    if [[ -f "go.mod" ]]; then
        echo "go build ./..."
        return 0
    fi

    if [[ -f "Makefile" ]]; then
        echo "make"
        return 0
    fi

    echo "unknown"
}

# Run the build command
# Usage: run_build [--capture]
run_build() {
    local capture=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --capture)
                capture=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local cmd
    cmd=$(detect_build_command)

    if [[ "$cmd" == "unknown" ]]; then
        echo "Unknown build system"
        return 1
    fi

    if $capture; then
        mkdir -p .claude
        set +e
        $cmd 2>&1 | tee "$BUILD_OUTPUT_FILE"
        local exit_code=${PIPESTATUS[0]}
        set -e
        return $exit_code
    else
        $cmd
    fi
}

# Parse build errors from output
# Usage: parse_build_errors "file"
parse_build_errors() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi

    local content
    content=$(cat "$file")

    # Parse TypeScript errors: src/file.ts(10,5): error TS2322: message
    while IFS= read -r line; do
        # Match TypeScript error format
        if [[ "$line" == *"error TS"* ]]; then
            # Extract file and line: src/index.ts(10,5):
            local ts_file ts_line ts_code ts_msg
            ts_file=$(echo "$line" | sed -n 's/^\([^(]*\)(.*/\1/p')
            ts_line=$(echo "$line" | sed -n 's/[^(]*(\([0-9]*\),.*/\1/p')
            ts_code=$(echo "$line" | sed -n 's/.*error \(TS[0-9]*\).*/\1/p')
            ts_msg=$(echo "$line" | sed -n 's/.*error TS[0-9]*: \(.*\)/\1/p')

            if [[ -n "$ts_file" ]]; then
                echo "File: $ts_file, line $ts_line"
                echo "Error: $ts_code - $ts_msg"
            fi
        fi
    done < "$file"
}

