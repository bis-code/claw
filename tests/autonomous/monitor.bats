#!/usr/bin/env bats
# TDD Tests for autonomous monitor

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    [[ -f "$PROJECT_ROOT/lib/autonomous/monitor.sh" ]] && source "$PROJECT_ROOT/lib/autonomous/monitor.sh"
    [[ -f "$PROJECT_ROOT/lib/autonomous/executor.sh" ]] && source "$PROJECT_ROOT/lib/autonomous/executor.sh"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Helper Functions
# ============================================================================

@test "monitor: truncate shortens long strings" {
    run truncate "This is a very long string that should be truncated" 20
    assert_success
    assert_output "This is a very lo..."
}

@test "monitor: truncate preserves short strings" {
    run truncate "Short" 20
    assert_success
    assert_output "Short"
}

@test "monitor: get_spinner returns spinner frame" {
    run get_spinner
    assert_success
    # Should be one of the spinner frames
    [[ "$output" =~ ^[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]$ ]]
}

# ============================================================================
# Status Display
# ============================================================================

@test "monitor: show_status works without queue" {
    cd "$TMP_DIR"

    run show_status
    assert_success
    assert_output --partial "No queue initialized"
}

@test "monitor: show_status shows queue counts" {
    cd "$TMP_DIR"
    init_task_queue
    add_task "Task 1" "high"
    add_task "Task 2" "medium"

    run show_status
    assert_success
    assert_output --partial "Pending"
    assert_output --partial "2"
}

@test "monitor: show_status shows completed count" {
    cd "$TMP_DIR"
    init_task_queue
    local id=$(add_task "echo done" "high")
    complete_task "$id"

    run show_status
    assert_success
    assert_output --partial "Completed"
    assert_output --partial "1"
}

@test "monitor: show_status shows failed count" {
    cd "$TMP_DIR"
    init_task_queue
    local id=$(add_task "exit 1" "high")
    fail_task "$id"

    run show_status
    assert_success
    assert_output --partial "Failed"
    assert_output --partial "1"
}

@test "monitor: show_status shows running task" {
    cd "$TMP_DIR"
    init_task_queue
    local id=$(add_task "Running task" "high")
    start_task "$id"

    run show_status
    assert_success
    assert_output --partial "Running"
}

@test "monitor: show_status shows next pending task" {
    cd "$TMP_DIR"
    init_task_queue
    add_task "Next up task" "high"

    run show_status
    assert_success
    assert_output --partial "Next"
    assert_output --partial "Next up task"
}

# ============================================================================
# Progress Display
# ============================================================================

@test "monitor: shows progress bar" {
    cd "$TMP_DIR"
    init_task_queue

    # Add 4 tasks, complete 2
    local id1=$(add_task "Task 1" "high")
    local id2=$(add_task "Task 2" "high")
    add_task "Task 3" "high"
    add_task "Task 4" "high"
    complete_task "$id1"
    complete_task "$id2"

    run show_status
    assert_success
    assert_output --partial "Progress"
    assert_output --partial "50%"
}

# ============================================================================
# Help
# ============================================================================

@test "monitor: --help shows usage" {
    run monitor_main --help
    assert_success
    assert_output --partial "Usage"
    assert_output --partial "--status"
    assert_output --partial "--watch"
}

# ============================================================================
# Logging
# ============================================================================

@test "monitor: displays activity log when present" {
    cd "$TMP_DIR"
    mkdir -p .claude
    echo "Task started: Test task" > .claude/autonomous.log
    echo "Task completed: Test task" >> .claude/autonomous.log

    # Test the display_activity function directly
    run display_activity
    assert_success
    assert_output --partial "Task started"
    assert_output --partial "Task completed"
}

@test "monitor: handles missing log gracefully" {
    cd "$TMP_DIR"
    mkdir -p .claude

    run display_activity
    assert_success
    assert_output --partial "No activity log"
}
