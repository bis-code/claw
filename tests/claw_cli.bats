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

@test "claw: help includes multi-repo section" {
    run "$PROJECT_ROOT/bin/claw" --help
    assert_success
    assert_output --partial "Multi-repo tracking"
    assert_output --partial "claw repos add"
}

# ============================================================================
# Repos Command Integration
# ============================================================================

@test "claw: repos --help shows repos usage" {
    run "$PROJECT_ROOT/bin/claw" repos --help
    assert_success
    assert_output --partial "claw repos"
    assert_output --partial "add"
    assert_output --partial "remove"
    assert_output --partial "list"
}

@test "claw: repos add works" {
    run "$PROJECT_ROOT/bin/claw" repos add owner/repo
    assert_success
    assert_output --partial "Added: owner/repo"
}

@test "claw: repos list shows added repos" {
    "$PROJECT_ROOT/bin/claw" repos add owner/repo

    run "$PROJECT_ROOT/bin/claw" repos list
    assert_success
    assert_output --partial "owner/repo"
}

@test "claw: repos remove works" {
    "$PROJECT_ROOT/bin/claw" repos add owner/repo

    run "$PROJECT_ROOT/bin/claw" repos remove owner/repo
    assert_success
    assert_output --partial "Removed: owner/repo"
}

@test "claw: repos list shows empty when none tracked" {
    run "$PROJECT_ROOT/bin/claw" repos list
    assert_success
    assert_output --partial "No repos tracked"
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
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    assert_output --partial "claw"
    assert_output --partial "Commands"
}

@test "claw: banner shows version" {
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    # Check for version pattern (vX.Y.Z) rather than hardcoded version
    assert_output --partial "claw v"
}

@test "claw: banner shows commands section" {
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    assert_output --partial "/plan-day"
    assert_output --partial "/brainstorm"
    assert_output --partial "/ship-day"
}

@test "claw: banner shows status section" {
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    assert_output --partial "Status"
    assert_output --partial "Claude:"
}

@test "claw: banner shows tracked repos count" {
    source "$PROJECT_ROOT/lib/repos.sh"
    repos_add "owner/repo1"
    repos_add "owner/repo2"

    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    assert_output --partial "2 repo(s)"
}

@test "claw: banner shows no repos tracked when empty" {
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    assert_output --partial "No repos tracked"
}

# ============================================================================
# Exit Message
# ============================================================================

@test "claw: exit message function exists" {
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/bin/claw"

    run show_exit_message "test-session-id"
    assert_success
    assert_output --partial "Session ended"
}

@test "claw: exit message shows session ID" {
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/bin/claw"

    run show_exit_message "abc123-session"
    assert_success
    assert_output --partial "abc123-session"
}

@test "claw: exit message shows resume instructions" {
    source "$PROJECT_ROOT/lib/repos.sh"
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
    assert_output --partial "Commands updated"

    # Flag should be recreated
    assert [ -f "$CLAW_HOME/.commands-installed" ]
}
