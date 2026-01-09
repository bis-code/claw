#!/usr/bin/env bats
# Real-world integration tests
# Tests that claw works correctly in realistic scenarios
#
# Current claw is a simplified claude wrapper with:
# - project create/add-repo/show/issues
# - templates list/install
# - issues
# - --setup-leann, --update

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    export CLAW_HOME="$TMP_DIR/claw-home"
    export CLAUDE_HOME="$TMP_DIR/claude-home"
    mkdir -p "$CLAW_HOME" "$CLAUDE_HOME"
    # Skip leann setup in tests
    touch "$CLAW_HOME/.leann-mcp-configured"
    # Mock claude command
    mkdir -p "$TMP_DIR/bin"
    echo '#!/bin/bash' > "$TMP_DIR/bin/claude"
    echo 'echo "claude mock: $*"' >> "$TMP_DIR/bin/claude"
    chmod +x "$TMP_DIR/bin/claude"
    export PATH="$TMP_DIR/bin:$PATH"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Basic CLI Tests
# ============================================================================

@test "claw: --version works" {
    run "$PROJECT_ROOT/bin/claw" --version
    assert_success
    assert_output --partial "claw v"
}

@test "claw: --help works" {
    run "$PROJECT_ROOT/bin/claw" --help
    assert_success
    assert_output --partial "Command Line Automated Workflow"
}

@test "claw: --update works" {
    run "$PROJECT_ROOT/bin/claw" --update
    assert_success
    assert_output --partial "Claude configuration updated"
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "edge case: claw works in deeply nested directory" {
    mkdir -p "$TMP_DIR/a/b/c/d/e/project"
    cd "$TMP_DIR/a/b/c/d/e/project"

    run "$PROJECT_ROOT/bin/claw" --version
    assert_success
}

@test "edge case: claw works with spaces in path" {
    mkdir -p "$TMP_DIR/My Project/src"
    cd "$TMP_DIR/My Project"

    run "$PROJECT_ROOT/bin/claw" --version
    assert_success
}

@test "edge case: claw works with unicode in path" {
    mkdir -p "$TMP_DIR/项目/src"
    cd "$TMP_DIR/项目"

    run "$PROJECT_ROOT/bin/claw" --version
    assert_success
}

# ============================================================================
# Git Repo Context Tests
# ============================================================================

@test "git context: claw works inside git repo" {
    mkdir -p "$TMP_DIR/git-project"
    cd "$TMP_DIR/git-project"
    git init -q

    run "$PROJECT_ROOT/bin/claw" --version
    assert_success
}
