#!/usr/bin/env bats
# TDD Tests for feedback loop (test runner & error parser)
# These tests define the expected behavior BEFORE implementation

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    [[ -f "$PROJECT_ROOT/lib/autonomous/feedback.sh" ]] && source "$PROJECT_ROOT/lib/autonomous/feedback.sh"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Test Detection
# ============================================================================

@test "feedback: detect_test_framework identifies npm test" {
    # Enabled
    cd "$TMP_DIR"
    echo '{"scripts": {"test": "jest"}}' > package.json

    run detect_test_framework
    assert_success
    assert_output "npm"
}

@test "feedback: detect_test_framework identifies pytest" {
    # Enabled
    cd "$TMP_DIR"
    echo "[tool.pytest]" > pyproject.toml

    run detect_test_framework
    assert_success
    assert_output "pytest"
}

@test "feedback: detect_test_framework identifies cargo test" {
    # Enabled
    cd "$TMP_DIR"
    echo "[package]" > Cargo.toml

    run detect_test_framework
    assert_success
    assert_output "cargo"
}

@test "feedback: detect_test_framework identifies go test" {
    # Enabled
    cd "$TMP_DIR"
    echo "module test" > go.mod

    run detect_test_framework
    assert_success
    assert_output "go"
}

@test "feedback: detect_test_framework returns unknown for no framework" {
    # Enabled
    cd "$TMP_DIR"

    run detect_test_framework
    assert_success
    assert_output "unknown"
}

# ============================================================================
# Test Execution
# ============================================================================

@test "feedback: run_tests executes detected framework" {
    # Enabled
    cd "$TMP_DIR"
    echo '{"scripts": {"test": "echo TESTS_PASSED"}}' > package.json

    run run_tests
    assert_success
    assert_output --partial "TESTS_PASSED"
}

@test "feedback: run_tests returns failure on test failure" {
    # Enabled
    cd "$TMP_DIR"
    echo '{"scripts": {"test": "exit 1"}}' > package.json

    run run_tests
    assert_failure
}

@test "feedback: run_tests captures output" {
    # Enabled
    cd "$TMP_DIR"
    echo '{"scripts": {"test": "echo line1 && echo line2"}}' > package.json

    run run_tests --capture
    assert_success
    assert [ -f ".claude/test-output.log" ]
}

# ============================================================================
# Error Parsing
# ============================================================================

@test "feedback: parse_test_errors extracts jest errors" {
    # Enabled
    cd "$TMP_DIR"
    cat > test-output.log << 'EOF'
FAIL src/utils.test.js
  ● add › should add two numbers
    expect(received).toBe(expected)
    Expected: 5
    Received: 4
      at Object.<anonymous> (src/utils.test.js:5:18)
EOF

    run parse_test_errors test-output.log
    assert_success
    assert_output --partial "src/utils.test.js"
    assert_output --partial "line 5"
    assert_output --partial "Expected: 5"
}

@test "feedback: parse_test_errors extracts pytest errors" {
    # Enabled
    cd "$TMP_DIR"
    cat > test-output.log << 'EOF'
FAILED tests/test_utils.py::test_add - AssertionError: assert 4 == 5
E       assert 4 == 5
E        +  where 4 = add(2, 2)
EOF

    run parse_test_errors test-output.log
    assert_success
    assert_output --partial "test_utils.py"
    assert_output --partial "test_add"
    assert_output --partial "assert 4 == 5"
}

@test "feedback: parse_test_errors returns structured JSON" {
    # Enabled
    cd "$TMP_DIR"
    cat > test-output.log << 'EOF'
FAIL src/test.js
  ● test name
    Error message
EOF

    run parse_test_errors test-output.log --json
    assert_success
    assert_output --partial '"file":'
    assert_output --partial '"error":'
}

# ============================================================================
# Fix Suggestions
# ============================================================================

@test "feedback: suggest_fix provides guidance for common errors" {
    # Enabled
    cd "$TMP_DIR"

    run suggest_fix "TypeError: Cannot read property 'x' of undefined"
    assert_success
    assert_output --partial "null check"
}

@test "feedback: suggest_fix handles assertion failures" {
    # Enabled
    cd "$TMP_DIR"

    run suggest_fix "Expected 5 but received 4"
    assert_success
    assert_output --partial "return value"
}

# ============================================================================
# Feedback Loop
# ============================================================================

@test "feedback: feedback_loop runs tests and retries on failure" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p src

    # Create a test that fails first, then passes
    cat > run_test.sh << 'EOF'
#!/bin/bash
if [ -f .retry ]; then
    echo "PASS"
    exit 0
else
    touch .retry
    echo "FAIL: Expected 5, got 4"
    exit 1
fi
EOF
    chmod +x run_test.sh

    run feedback_loop "./run_test.sh" --max-retries 3
    assert_success
    assert_output --partial "PASS"
}

@test "feedback: feedback_loop gives up after max retries" {
    # Enabled
    cd "$TMP_DIR"

    cat > always_fail.sh << 'EOF'
#!/bin/bash
echo "FAIL"
exit 1
EOF
    chmod +x always_fail.sh

    run feedback_loop "./always_fail.sh" --max-retries 2
    assert_failure
    assert_output --partial "Max retries exceeded"
}

@test "feedback: feedback_loop tracks retry count" {
    # Enabled
    cd "$TMP_DIR"

    cat > always_fail.sh << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x always_fail.sh

    run feedback_loop "./always_fail.sh" --max-retries 3
    assert_failure
    assert_output --partial "Retry 1"
    assert_output --partial "Retry 2"
    assert_output --partial "Retry 3"
}

# ============================================================================
# Build Detection
# ============================================================================

@test "feedback: detect_build_command identifies npm build" {
    # Enabled
    cd "$TMP_DIR"
    echo '{"scripts": {"build": "tsc"}}' > package.json

    run detect_build_command
    assert_success
    assert_output "npm run build"
}

@test "feedback: run_build executes build and captures errors" {
    # Enabled
    cd "$TMP_DIR"
    echo '{"scripts": {"build": "echo BUILD_SUCCESS"}}' > package.json

    run run_build
    assert_success
    assert_output --partial "BUILD_SUCCESS"
}

@test "feedback: parse_build_errors extracts TypeScript errors" {
    # Enabled
    cd "$TMP_DIR"
    cat > build-output.log << 'EOF'
src/index.ts(10,5): error TS2322: Type 'string' is not assignable to type 'number'.
EOF

    run parse_build_errors build-output.log
    assert_success
    assert_output --partial "src/index.ts"
    assert_output --partial "line 10"
    assert_output --partial "TS2322"
}
