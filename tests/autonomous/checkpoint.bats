#!/usr/bin/env bats
# TDD Tests for checkpoint/state management
# These tests define the expected behavior BEFORE implementation

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    [[ -f "$PROJECT_ROOT/lib/autonomous/checkpoint.sh" ]] && source "$PROJECT_ROOT/lib/autonomous/checkpoint.sh"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Checkpoint Creation
# ============================================================================

@test "checkpoint: create_checkpoint saves current state" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude
    echo '{"tasks": []}' > .claude/queue.json

    run create_checkpoint "before-feature-x"
    assert_success
    assert [ -f ".claude/checkpoints/before-feature-x.json" ]
}

@test "checkpoint: create_checkpoint includes timestamp" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude
    create_checkpoint "test-checkpoint"

    run cat .claude/checkpoints/test-checkpoint.json
    assert_output --partial "timestamp"
}

@test "checkpoint: create_checkpoint includes queue state" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude
    echo '{"tasks": [{"id": 1, "title": "Test"}]}' > .claude/queue.json
    create_checkpoint "with-tasks"

    run cat .claude/checkpoints/with-tasks.json
    assert_output --partial "Test"
}

@test "checkpoint: create_checkpoint includes git state" {
    # Enabled
    cd "$TMP_DIR"
    git init -q
    echo "test" > file.txt
    git add file.txt
    git commit -m "Initial" -q
    mkdir -p .claude

    create_checkpoint "git-state"

    run cat .claude/checkpoints/git-state.json
    assert_output --partial "commit"
}

# ============================================================================
# Checkpoint Restoration
# ============================================================================

@test "checkpoint: restore_checkpoint loads saved state" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude
    echo '{"tasks": [{"id": 1}]}' > .claude/queue.json
    create_checkpoint "saved-state"

    # Modify current state
    echo '{"tasks": []}' > .claude/queue.json

    run restore_checkpoint "saved-state"
    assert_success

    run cat .claude/queue.json
    assert_output --partial '"id": 1'
}

@test "checkpoint: restore_checkpoint fails for nonexistent checkpoint" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude

    run restore_checkpoint "nonexistent"
    assert_failure
    assert_output --partial "not found"
}

@test "checkpoint: restore_checkpoint optionally resets git" {
    # Enabled
    cd "$TMP_DIR"
    git init -q
    echo "original" > file.txt
    git add file.txt
    git commit -m "Original" -q
    mkdir -p .claude

    create_checkpoint "original-commit"

    echo "modified" > file.txt
    git add file.txt
    git commit -m "Modified" -q

    run restore_checkpoint "original-commit" --reset-git
    assert_success

    run cat file.txt
    assert_output "original"
}

# ============================================================================
# Checkpoint Listing
# ============================================================================

@test "checkpoint: list_checkpoints shows all checkpoints" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude
    create_checkpoint "checkpoint-1"
    create_checkpoint "checkpoint-2"

    run list_checkpoints
    assert_success
    assert_output --partial "checkpoint-1"
    assert_output --partial "checkpoint-2"
}

@test "checkpoint: list_checkpoints shows empty for no checkpoints" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude

    run list_checkpoints
    assert_success
    assert_output --partial "No checkpoints"
}

# ============================================================================
# Auto-Checkpoint
# ============================================================================

@test "checkpoint: auto_checkpoint creates checkpoint before risky operations" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude

    run auto_checkpoint "before-deploy"
    assert_success
    assert [ -f ".claude/checkpoints/auto-before-deploy.json" ]
}

@test "checkpoint: checkpoint rotation keeps last N checkpoints" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude

    for i in {1..10}; do
        create_checkpoint "checkpoint-$i"
    done

    run list_checkpoints --count
    # Should only keep last 5 by default
    assert_output "5"
}

# ============================================================================
# Session Persistence
# ============================================================================

@test "checkpoint: save_session persists context across restarts" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude

    save_session "current_task" "Implement feature X"
    save_session "progress" "50%"

    run get_session "current_task"
    assert_output "Implement feature X"

    run get_session "progress"
    assert_output "50%"
}

@test "checkpoint: clear_session removes session data" {
    # Enabled
    cd "$TMP_DIR"
    mkdir -p .claude

    save_session "key" "value"
    clear_session

    run get_session "key"
    assert_output ""
}
