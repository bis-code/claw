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
# Repos Integration
# ============================================================================

@test "e2e: repos workflow - add, list, remove" {
    # Add repos
    run "$PROJECT_ROOT/bin/claw" repos add org/repo1
    assert_success
    assert_output --partial "Added"

    run "$PROJECT_ROOT/bin/claw" repos add org/repo2
    assert_success

    # List shows both
    run "$PROJECT_ROOT/bin/claw" repos list
    assert_success
    assert_output --partial "org/repo1"
    assert_output --partial "org/repo2"
    assert_output --partial "2"

    # Remove one
    run "$PROJECT_ROOT/bin/claw" repos remove org/repo1
    assert_success
    assert_output --partial "Removed"

    # List shows only remaining
    run "$PROJECT_ROOT/bin/claw" repos list
    assert_success
    assert_output --partial "org/repo2"
    refute_output --partial "org/repo1"
}

@test "e2e: repos validation - rejects invalid format" {
    run "$PROJECT_ROOT/bin/claw" repos add "invalid-no-slash"
    assert_failure

    run "$PROJECT_ROOT/bin/claw" repos add "/no-owner"
    assert_failure

    run "$PROJECT_ROOT/bin/claw" repos add "no-repo/"
    assert_failure
}

@test "e2e: repos idempotent - no duplicates" {
    "$PROJECT_ROOT/bin/claw" repos add org/repo
    "$PROJECT_ROOT/bin/claw" repos add org/repo
    "$PROJECT_ROOT/bin/claw" repos add org/repo

    run "$PROJECT_ROOT/bin/claw" repos list
    assert_success
    # Count should be 1, not 3
    assert_output --partial "1"
}

# ============================================================================
# Issues Integration
# ============================================================================

@test "e2e: issues command runs without error" {
    # Even without repos, should not error
    run "$PROJECT_ROOT/bin/claw" issues
    assert_success
}

# ============================================================================
# Update Command
# ============================================================================

@test "e2e: --update reinstalls commands" {
    touch "$CLAW_HOME/.commands-installed"

    run "$PROJECT_ROOT/bin/claw" --update
    assert_success
    assert_output --partial "Commands updated"
}
