#!/usr/bin/env bats
# Integration tests for claw CLI (simplified architecture)

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
# Installation
# ============================================================================

@test "install.sh: installs to custom prefix" {
    run "$PROJECT_ROOT/install.sh" --prefix "$TMP_DIR"
    assert_success
}

# ============================================================================
# Basic CLI
# ============================================================================

@test "claw: shows help with --help" {
    run "$PROJECT_ROOT/bin/claw" --help
    assert_success
    assert_output --partial "Command Line Automated Workflow"
}

@test "claw: shows version with --version" {
    run "$PROJECT_ROOT/bin/claw" --version
    assert_success
    assert_output --partial "claw v"
}

# ============================================================================
# Issues Integration
# ============================================================================

@test "e2e: issues command runs without error" {
    # Without a project, should show helpful message
    run "$PROJECT_ROOT/bin/claw" issues
    assert_success
    assert_output --partial "Not in a project"
}

# ============================================================================
# Update Command
# ============================================================================

@test "e2e: --update reinstalls commands" {
    touch "$CLAW_HOME/.commands-installed"

    run "$PROJECT_ROOT/bin/claw" --update
    assert_success
    assert_output --partial "Claude configuration updated"
}
