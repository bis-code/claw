#!/usr/bin/env bats
# Tests for consistent boolean parameter handling

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# ============================================================================
# Boolean Parameter Pattern Tests
# ============================================================================

@test "boolean params: true value works with if statement" {
    local flag=true

    if $flag; then
        result="flag is true"
    else
        result="flag is false"
    fi

    [[ "$result" == "flag is true" ]]
}

@test "boolean params: false value works with if statement" {
    local flag=false

    if $flag; then
        result="flag is true"
    else
        result="flag is false"
    fi

    [[ "$result" == "flag is false" ]]
}

@test "boolean params: default false works" {
    test_function() {
        local flag="${1:-false}"
        if $flag; then
            echo "true"
        else
            echo "false"
        fi
    }

    run test_function
    assert_output "false"
}

@test "boolean params: passing true works" {
    test_function() {
        local flag="${1:-false}"
        if $flag; then
            echo "true"
        else
            echo "false"
        fi
    }

    run test_function true
    assert_output "true"
}

@test "boolean params: negation with if ! works" {
    local flag=false

    if ! $flag; then
        result="flag is false"
    else
        result="flag is true"
    fi

    [[ "$result" == "flag is false" ]]
}

# ============================================================================
# Inconsistent Pattern Detection Tests
# ============================================================================

@test "boolean params: string comparison '==' should be avoided" {
    # This test documents the pattern we want to AVOID
    local flag="true"

    # OLD PATTERN (inconsistent):
    if [[ "$flag" == "true" ]]; then
        old_result="matches"
    else
        old_result="no match"
    fi

    # NEW PATTERN (preferred):
    if $flag; then
        new_result="matches"
    else
        new_result="no match"
    fi

    # Both should give same result, but new pattern is cleaner
    [[ "$old_result" == "$new_result" ]]
}

@test "boolean params: only use 'true' or 'false' literals" {
    # This test documents that booleans should ONLY be "true" or "false"
    # Empty strings or other values will cause errors
    local flag_true="true"
    local flag_false="false"

    # Both patterns should work
    if $flag_true; then
        result1="pass"
    fi

    if ! $flag_false; then
        result2="pass"
    fi

    [[ "$result1" == "pass" ]]
    [[ "$result2" == "pass" ]]
}
