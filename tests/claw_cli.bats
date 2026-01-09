#!/usr/bin/env bats
# TDD Tests for claw CLI

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
# Version and Help
# ============================================================================

@test "claw: --version shows version" {
    run "$PROJECT_ROOT/bin/claw" --version
    assert_success
    assert_output --partial "claw v"
}

@test "claw: -v shows version" {
    run "$PROJECT_ROOT/bin/claw" -v
    assert_success
    assert_output --partial "claw v"
}

@test "claw: --help shows usage" {
    run "$PROJECT_ROOT/bin/claw" --help
    assert_success
    assert_output --partial "Command Line Automated Workflow"
    assert_output --partial "Usage:"
}

@test "claw: -h shows usage" {
    run "$PROJECT_ROOT/bin/claw" -h
    assert_success
    assert_output --partial "Usage:"
}

@test "claw: help includes project management section" {
    run "$PROJECT_ROOT/bin/claw" --help
    assert_success
    assert_output --partial "Project management"
    assert_output --partial "claw project"
}

# ============================================================================
# Issues Command
# ============================================================================

@test "claw: issues command exists" {
    # This will fail if gh is not authenticated, but should not error on command not found
    run "$PROJECT_ROOT/bin/claw" issues 2>&1
    # Should either succeed or fail with "no issues" not "command not found"
    refute_output --partial "Unknown"
}

# ============================================================================
# Banner Function
# ============================================================================

@test "claw: banner function exists and runs" {
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    assert_output --partial "claw"
    assert_output --partial "Commands"
}

@test "claw: banner shows version" {
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    # Check for version pattern (vX.Y.Z) rather than hardcoded version
    assert_output --partial "claw v"
}

@test "claw: banner shows commands section" {
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    assert_output --partial "/plan-day"
    assert_output --partial "/brainstorm"
    assert_output --partial "/ship-day"
}

@test "claw: banner shows status section" {
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    assert_output --partial "Status"
    assert_output --partial "Claude:"
}

@test "claw: banner shows repo info when in git repo" {
    source "$PROJECT_ROOT/lib/projects.sh"

    # Create a git repo for this test
    mkdir -p "$TMP_DIR/test-repo"
    cd "$TMP_DIR/test-repo"
    git init -q
    git remote add origin https://github.com/owner/repo.git

    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    # When in a git repo, shows repo info
    assert_output --partial "Repo:"
}

# ============================================================================
# Exit Message
# ============================================================================

@test "claw: exit message function exists" {
    source "$PROJECT_ROOT/bin/claw"

    run show_exit_message "test-session-id"
    assert_success
    assert_output --partial "Session ended"
}

@test "claw: exit message shows session ID" {
    source "$PROJECT_ROOT/bin/claw"

    run show_exit_message "abc123-session"
    assert_success
    assert_output --partial "abc123-session"
}

@test "claw: exit message shows resume instructions" {
    source "$PROJECT_ROOT/bin/claw"

    run show_exit_message "test-id"
    assert_success
    assert_output --partial "--resume"
    assert_output --partial "--continue"
}

# ============================================================================
# Update Command
# ============================================================================

@test "claw: --update reinstalls commands" {
    mkdir -p "$CLAW_HOME"
    touch "$CLAW_HOME/.commands-installed"

    run "$PROJECT_ROOT/bin/claw" --update
    assert_success
    assert_output --partial "Claude configuration updated"

    # Flag should be recreated
    assert [ -f "$CLAW_HOME/.commands-installed" ]
}
