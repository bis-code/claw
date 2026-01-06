#!/usr/bin/env bats
# TDD Tests for blocker detection
# These tests define the expected behavior BEFORE implementation

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    [[ -f "$PROJECT_ROOT/lib/autonomous/blocker.sh" ]] && source "$PROJECT_ROOT/lib/autonomous/blocker.sh"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Blocker Detection
# ============================================================================

@test "blocker: detect_blocker identifies missing dependency" {
    cd "$TMP_DIR"

    run detect_blocker "Module not found: 'some-package'"
    assert_success
    assert_output --partial "missing_dependency"
    assert_output --partial "some-package"
}

@test "blocker: detect_blocker identifies permission denied" {
    cd "$TMP_DIR"

    run detect_blocker "Permission denied: /etc/passwd"
    assert_success
    assert_output --partial "permission"
}

@test "blocker: detect_blocker identifies network error" {
    cd "$TMP_DIR"

    run detect_blocker "ECONNREFUSED: Connection refused"
    assert_success
    assert_output --partial "network"
}

@test "blocker: detect_blocker identifies rate limit" {
    cd "$TMP_DIR"

    run detect_blocker "API rate limit exceeded"
    assert_success
    assert_output --partial "rate_limit"
}

@test "blocker: detect_blocker identifies authentication failure" {
    cd "$TMP_DIR"

    run detect_blocker "401 Unauthorized"
    assert_success
    assert_output --partial "auth"
}

@test "blocker: detect_blocker returns unknown for unrecognized errors" {
    cd "$TMP_DIR"

    run detect_blocker "Some random error message"
    assert_success
    assert_output --partial "unknown"
}

# ============================================================================
# Blocker Classification
# ============================================================================

@test "blocker: classify_blocker distinguishes recoverable vs fatal" {
    cd "$TMP_DIR"

    run classify_blocker "missing_dependency"
    assert_success
    assert_output "recoverable"

    run classify_blocker "permission"
    assert_success
    assert_output "fatal"
}

@test "blocker: is_recoverable returns true for recoverable blockers" {
    cd "$TMP_DIR"

    run is_recoverable "missing_dependency"
    assert_success

    run is_recoverable "permission"
    assert_failure
}

# ============================================================================
# Blocker Resolution
# ============================================================================

@test "blocker: suggest_resolution provides fix for missing dependency" {
    cd "$TMP_DIR"
    echo '{}' > package.json

    run suggest_resolution "missing_dependency" "lodash"
    assert_success
    assert_output --partial "npm install lodash"
}

@test "blocker: suggest_resolution provides fix for rate limit" {
    cd "$TMP_DIR"

    run suggest_resolution "rate_limit"
    assert_success
    assert_output --partial "wait"
}

@test "blocker: auto_resolve attempts to fix recoverable blockers" {
    cd "$TMP_DIR"
    echo '{}' > package.json

    # Mock npm
    npm() { echo "installed $*"; }
    export -f npm

    run auto_resolve "missing_dependency" "lodash"
    assert_success
    assert_output --partial "installed"
}

@test "blocker: auto_resolve fails for fatal blockers" {
    cd "$TMP_DIR"

    run auto_resolve "permission" "/etc/passwd"
    assert_failure
    assert_output --partial "Cannot auto-resolve"
}

# ============================================================================
# Human Intervention
# ============================================================================

@test "blocker: request_human_help creates intervention request" {
    cd "$TMP_DIR"
    mkdir -p .claude

    run request_human_help "Need API credentials"
    assert_success
    assert [ -f ".claude/intervention-request.json" ]
}

@test "blocker: intervention request contains context" {
    cd "$TMP_DIR"
    mkdir -p .claude

    request_human_help "Need API credentials" --context "Trying to deploy to production"

    run cat .claude/intervention-request.json
    assert_output --partial "Need API credentials"
    assert_output --partial "deploy to production"
}

@test "blocker: check_intervention_resolved detects human response" {
    cd "$TMP_DIR"
    mkdir -p .claude

    request_human_help "Need API credentials"
    echo '{"resolved": true, "action": "Added credentials to .env"}' > .claude/intervention-response.json

    run check_intervention_resolved
    assert_success
    assert_output --partial "Added credentials"
}

@test "blocker: wait_for_intervention blocks until resolved" {
    cd "$TMP_DIR"
    mkdir -p .claude

    # Background process to simulate human response
    (sleep 1 && echo '{"resolved": true}' > .claude/intervention-response.json) &

    request_human_help "Test"
    run wait_for_intervention --timeout 5
    assert_success
}

# ============================================================================
# Blocker History
# ============================================================================

@test "blocker: log_blocker records blocker occurrence" {
    cd "$TMP_DIR"
    mkdir -p .claude

    run log_blocker "missing_dependency" "lodash" "Auto-resolved"
    assert_success
    assert [ -f ".claude/blocker-history.json" ]
}

@test "blocker: get_blocker_history returns past blockers" {
    cd "$TMP_DIR"
    mkdir -p .claude

    log_blocker "missing_dependency" "lodash" "Auto-resolved"
    log_blocker "rate_limit" "github" "Waited 60s"

    run get_blocker_history
    assert_success
    assert_output --partial "lodash"
    assert_output --partial "github"
}

@test "blocker: analyze_blockers identifies patterns" {
    cd "$TMP_DIR"
    mkdir -p .claude

    # Log same blocker multiple times
    log_blocker "missing_dependency" "lodash"
    log_blocker "missing_dependency" "lodash"
    log_blocker "missing_dependency" "lodash"

    run analyze_blockers
    assert_success
    assert_output --partial "lodash"
    assert_output --partial "3 occurrences"
}

# ============================================================================
# Confidence Scoring
# ============================================================================

@test "blocker: get_confidence_score returns score based on history" {
    cd "$TMP_DIR"
    mkdir -p .claude

    # No history = high confidence
    run get_confidence_score "simple_task"
    assert_success
    assert_output "100"

    # Add some failures
    log_blocker "test_failure" "simple_task"
    log_blocker "test_failure" "simple_task"

    run get_confidence_score "simple_task"
    assert_success
    # Should be lower now
    [[ "$output" -lt 100 ]]
}

@test "blocker: should_proceed returns false below threshold" {
    cd "$TMP_DIR"
    mkdir -p .claude

    # Simulate many failures
    for i in {1..10}; do
        log_blocker "test_failure" "risky_task"
    done

    run should_proceed "risky_task" --threshold 50
    assert_failure
}
