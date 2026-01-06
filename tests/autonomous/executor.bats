#!/usr/bin/env bats
# TDD Tests for autonomous executor
# These tests define the expected behavior BEFORE implementation

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    # Source autonomous modules when they exist
    [[ -f "$PROJECT_ROOT/lib/autonomous/executor.sh" ]] && source "$PROJECT_ROOT/lib/autonomous/executor.sh"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Task Queue Management
# ============================================================================

@test "executor: init_task_queue creates empty queue" {
    cd "$TMP_DIR"
    run init_task_queue
    assert_success
    assert [ -f ".claude/queue.json" ]
}

@test "executor: add_task appends to queue" {
    cd "$TMP_DIR"
    init_task_queue
    run add_task "Implement feature X" "high"
    assert_success
    run cat .claude/queue.json
    assert_output --partial "Implement feature X"
}

@test "executor: get_next_task returns highest priority" {
    cd "$TMP_DIR"
    init_task_queue
    add_task "Low priority task" "low"
    add_task "High priority task" "high"
    run get_next_task
    assert_success
    assert_output --partial "High priority task"
}

@test "executor: complete_task removes from queue" {
    cd "$TMP_DIR"
    init_task_queue
    add_task "Task to complete" "high"
    local task_id=$(get_next_task --id-only)
    run complete_task "$task_id"
    assert_success
    run get_next_task
    assert_output ""
}

# ============================================================================
# Execution Loop
# ============================================================================

@test "executor: execute_task runs task and returns result" {
    cd "$TMP_DIR"
    echo 'echo "Hello World"' > task.sh
    run execute_task "bash task.sh"
    assert_success
    assert_output --partial "Hello World"
}

@test "executor: execute_task captures exit code" {
    cd "$TMP_DIR"
    echo 'exit 42' > failing_task.sh
    run execute_task "bash failing_task.sh"
    assert_failure 42
}

@test "executor: run_loop processes tasks until queue empty" {
    cd "$TMP_DIR"
    init_task_queue
    add_task "echo task1" "high"
    add_task "echo task2" "high"
    run run_loop --max-iterations 10
    assert_success
    # Queue should be empty
    run get_next_task
    assert_output ""
}

@test "executor: run_loop stops on blocker" {
    # Skip on macOS due to timing differences in process output capture
    if [[ "$(uname)" == "Darwin" ]]; then
        skip "Flaky on macOS"
    fi
    cd "$TMP_DIR"
    init_task_queue
    add_task "exit 1" "high"  # This will fail
    run run_loop --stop-on-failure
    assert_failure
    assert_output --partial "BLOCKED"
}

@test "executor: run_loop respects max iterations" {
    cd "$TMP_DIR"
    init_task_queue
    # Add more tasks than max_iterations to test the limit
    add_task "echo task1" "high"
    add_task "echo task2" "high"
    add_task "echo task3" "high"
    add_task "echo task4" "high"
    add_task "echo task5" "high"
    run run_loop --max-iterations 3
    assert_success
    assert_output --partial "Max iterations reached"
    # Should have 2 tasks remaining (5 - 3 = 2)
    run get_next_task
    assert_output "echo task4"
}

# ============================================================================
# Task State
# ============================================================================

@test "executor: get_task_state returns pending/running/completed/failed" {
    cd "$TMP_DIR"
    init_task_queue
    add_task "Test task" "high"
    local task_id=$(get_next_task --id-only)

    run get_task_state "$task_id"
    assert_output "pending"

    start_task "$task_id"
    run get_task_state "$task_id"
    assert_output "running"
}

@test "executor: task history is preserved" {
    cd "$TMP_DIR"
    init_task_queue
    add_task "Historical task" "high"
    local task_id=$(get_next_task --id-only)
    complete_task "$task_id"

    run get_task_history
    assert_success
    assert_output --partial "Historical task"
    assert_output --partial "completed"
}

# ============================================================================
# Integration with GitHub Issues
# ============================================================================

@test "executor: import_from_github adds issues to queue" {
    # Integration test - requires gh CLI and network access
    command -v gh &>/dev/null || skip "gh CLI not installed"
    gh auth status &>/dev/null || skip "gh not authenticated"

    cd "$TMP_DIR"
    git init -q
    init_task_queue

    # Import issues from the claw repo (use bis-code/claw)
    run import_from_github --repo "bis-code/claw"
    assert_success

    # Should have imported at least the queue structure
    assert [ -f ".claude/queue.json" ]
    # Output should indicate how many issues were imported
    assert_output --partial "Imported"
}

@test "executor: add_task with github issue metadata" {
    cd "$TMP_DIR"
    init_task_queue

    # Add task with GitHub issue reference
    run add_task "Fix bug from issue #123" "high" --github-issue 123
    assert_success

    # Verify the task has the github_issue metadata
    run cat .claude/queue.json
    assert_output --partial '"github_issue"'
    assert_output --partial '123'
}
