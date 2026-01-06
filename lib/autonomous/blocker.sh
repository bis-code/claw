#!/usr/bin/env bash
#
# blocker.sh - Blocker detection and resolution for claw
# Part of the TDD-driven autonomous execution system
#

set -euo pipefail

BLOCKER_HISTORY_FILE=".claude/blocker-history.json"
INTERVENTION_REQUEST_FILE=".claude/intervention-request.json"
INTERVENTION_RESPONSE_FILE=".claude/intervention-response.json"

# ============================================================================
# Blocker Detection
# ============================================================================

# Detect the type of blocker from an error message
# Usage: detect_blocker "error message"
# Returns: blocker_type and details as JSON
detect_blocker() {
    local error_message="$1"
    local blocker_type="unknown"
    local details=""

    # Check for missing dependency patterns
    if [[ "$error_message" =~ (Module not found|Cannot find module|No module named|ModuleNotFoundError|could not resolve|package .* not found) ]]; then
        blocker_type="missing_dependency"
        # Try to extract package name
        if [[ "$error_message" =~ \'([^\']+)\' ]]; then
            details="${BASH_REMATCH[1]}"
        elif [[ "$error_message" =~ \"([^\"]+)\" ]]; then
            details="${BASH_REMATCH[1]}"
        fi
    # Check for permission errors
    elif [[ "$error_message" =~ (Permission denied|EACCES|access denied|Operation not permitted) ]]; then
        blocker_type="permission"
        if [[ "$error_message" =~ :\ *(/[^ ]+) ]]; then
            details="${BASH_REMATCH[1]}"
        fi
    # Check for network errors
    elif [[ "$error_message" =~ (ECONNREFUSED|Connection refused|ETIMEDOUT|Network is unreachable|getaddrinfo|ENOTFOUND) ]]; then
        blocker_type="network"
    # Check for rate limiting
    elif [[ "$error_message" =~ (rate limit|too many requests|429|throttl) ]]; then
        blocker_type="rate_limit"
    # Check for authentication errors
    elif [[ "$error_message" =~ (401|Unauthorized|authentication failed|invalid.*token|invalid.*credentials|auth.*fail) ]]; then
        blocker_type="auth"
    fi

    # Output as JSON
    if command -v jq &>/dev/null; then
        jq -n --arg type "$blocker_type" --arg details "$details" \
            '{type: $type, details: $details}'
    else
        echo "{\"type\": \"$blocker_type\", \"details\": \"$details\"}"
    fi
}

# ============================================================================
# Blocker Classification
# ============================================================================

# Classify a blocker as recoverable or fatal
# Usage: classify_blocker "blocker_type"
classify_blocker() {
    local blocker_type="$1"

    case "$blocker_type" in
        missing_dependency|rate_limit|network)
            echo "recoverable"
            ;;
        permission|auth|unknown)
            echo "fatal"
            ;;
        *)
            echo "fatal"
            ;;
    esac
}

# Check if a blocker is recoverable
# Usage: is_recoverable "blocker_type"
# Returns: 0 if recoverable, 1 if fatal
is_recoverable() {
    local blocker_type="$1"
    local classification
    classification=$(classify_blocker "$blocker_type")

    [[ "$classification" == "recoverable" ]]
}

# ============================================================================
# Blocker Resolution
# ============================================================================

# Suggest a resolution for a blocker
# Usage: suggest_resolution "blocker_type" ["details"]
suggest_resolution() {
    local blocker_type="$1"
    local details="${2:-}"

    case "$blocker_type" in
        missing_dependency)
            # Detect package manager
            if [[ -f "package.json" ]]; then
                echo "npm install $details"
            elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
                echo "pip install $details"
            elif [[ -f "Cargo.toml" ]]; then
                echo "cargo add $details"
            else
                echo "Install missing dependency: $details"
            fi
            ;;
        rate_limit)
            echo "wait: Rate limit hit. Wait before retrying."
            ;;
        network)
            echo "retry: Network error. Check connection and retry."
            ;;
        permission)
            echo "manual: Permission denied. Requires human intervention."
            ;;
        auth)
            echo "manual: Authentication failed. Check credentials."
            ;;
        *)
            echo "unknown: No automatic resolution available."
            ;;
    esac
}

# Attempt to automatically resolve a blocker
# Usage: auto_resolve "blocker_type" ["details"]
auto_resolve() {
    local blocker_type="$1"
    local details="${2:-}"

    # Check if blocker is recoverable
    if ! is_recoverable "$blocker_type"; then
        echo "Cannot auto-resolve fatal blocker: $blocker_type"
        return 1
    fi

    case "$blocker_type" in
        missing_dependency)
            if [[ -f "package.json" ]]; then
                npm install "$details" 2>&1
            elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
                pip install "$details" 2>&1
            else
                echo "Cannot auto-resolve: unknown package manager"
                return 1
            fi
            ;;
        rate_limit)
            echo "Waiting 60 seconds for rate limit..."
            sleep 60
            ;;
        network)
            echo "Waiting 5 seconds before retry..."
            sleep 5
            ;;
        *)
            echo "Cannot auto-resolve: $blocker_type"
            return 1
            ;;
    esac
}

# ============================================================================
# Human Intervention
# ============================================================================

# Request human help for a blocker
# Usage: request_human_help "message" [--context "context"]
request_human_help() {
    local message="$1"
    local context=""

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --context)
                context="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    mkdir -p .claude

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if command -v jq &>/dev/null; then
        jq -n \
            --arg message "$message" \
            --arg context "$context" \
            --arg timestamp "$timestamp" \
            '{message: $message, context: $context, timestamp: $timestamp, resolved: false}' \
            > "$INTERVENTION_REQUEST_FILE"
    else
        echo "{\"message\": \"$message\", \"context\": \"$context\", \"timestamp\": \"$timestamp\", \"resolved\": false}" \
            > "$INTERVENTION_REQUEST_FILE"
    fi

    echo "Human intervention requested: $message"
}

# Check if human has responded to intervention request
# Usage: check_intervention_resolved
# Returns: 0 if resolved, 1 if not
check_intervention_resolved() {
    if [[ ! -f "$INTERVENTION_RESPONSE_FILE" ]]; then
        return 1
    fi

    if command -v jq &>/dev/null; then
        local resolved action
        resolved=$(jq -r '.resolved // false' "$INTERVENTION_RESPONSE_FILE")
        action=$(jq -r '.action // ""' "$INTERVENTION_RESPONSE_FILE")

        if [[ "$resolved" == "true" ]]; then
            echo "Intervention resolved: $action"
            return 0
        fi
    fi

    return 1
}

# Wait for human intervention with timeout
# Usage: wait_for_intervention [--timeout SECONDS]
wait_for_intervention() {
    local timeout=300  # 5 minutes default
    local interval=2

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --timeout)
                timeout="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if check_intervention_resolved; then
            return 0
        fi
        sleep "$interval"
        ((elapsed += interval)) || true
    done

    echo "Timeout waiting for intervention"
    return 1
}

# ============================================================================
# Blocker History
# ============================================================================

# Log a blocker occurrence
# Usage: log_blocker "type" "details" ["resolution"]
log_blocker() {
    local blocker_type="$1"
    local details="${2:-}"
    local resolution="${3:-}"

    mkdir -p .claude

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Initialize history file if it doesn't exist
    if [[ ! -f "$BLOCKER_HISTORY_FILE" ]]; then
        echo '{"blockers": []}' > "$BLOCKER_HISTORY_FILE"
    fi

    if command -v jq &>/dev/null; then
        local entry
        entry=$(jq -n \
            --arg type "$blocker_type" \
            --arg details "$details" \
            --arg resolution "$resolution" \
            --arg timestamp "$timestamp" \
            '{type: $type, details: $details, resolution: $resolution, timestamp: $timestamp}')

        jq --argjson entry "$entry" '.blockers += [$entry]' "$BLOCKER_HISTORY_FILE" \
            > "$BLOCKER_HISTORY_FILE.tmp" && mv "$BLOCKER_HISTORY_FILE.tmp" "$BLOCKER_HISTORY_FILE"
    fi
}

# Get blocker history
# Usage: get_blocker_history
get_blocker_history() {
    if [[ ! -f "$BLOCKER_HISTORY_FILE" ]]; then
        echo "[]"
        return 0
    fi

    if command -v jq &>/dev/null; then
        jq -r '.blockers[] | "\(.type): \(.details) - \(.resolution)"' "$BLOCKER_HISTORY_FILE"
    else
        cat "$BLOCKER_HISTORY_FILE"
    fi
}

# Analyze blocker patterns
# Usage: analyze_blockers
analyze_blockers() {
    if [[ ! -f "$BLOCKER_HISTORY_FILE" ]]; then
        echo "No blocker history"
        return 0
    fi

    if command -v jq &>/dev/null; then
        # Group by type and details, count occurrences
        jq -r '
            .blockers
            | group_by(.details)
            | map({details: .[0].details, type: .[0].type, count: length})
            | sort_by(-.count)
            | .[]
            | "\(.details): \(.count) occurrences (\(.type))"
        ' "$BLOCKER_HISTORY_FILE"
    fi
}

# ============================================================================
# Confidence Scoring
# ============================================================================

# Get confidence score for a task based on blocker history
# Usage: get_confidence_score "task_identifier"
# Returns: 0-100 score
get_confidence_score() {
    local task_id="$1"

    if [[ ! -f "$BLOCKER_HISTORY_FILE" ]]; then
        echo "100"
        return 0
    fi

    if command -v jq &>/dev/null; then
        local failure_count
        failure_count=$(jq --arg id "$task_id" '[.blockers[] | select(.details == $id)] | length' "$BLOCKER_HISTORY_FILE")

        # Calculate score: start at 100, subtract 10 for each failure
        local score=$((100 - failure_count * 10))
        [[ $score -lt 0 ]] && score=0

        echo "$score"
    else
        echo "100"
    fi
}

# Check if we should proceed with a task
# Usage: should_proceed "task_identifier" [--threshold SCORE]
# Returns: 0 if should proceed, 1 if not
should_proceed() {
    local task_id="$1"
    local threshold=50

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --threshold)
                threshold="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    local score
    score=$(get_confidence_score "$task_id")

    [[ $score -ge $threshold ]]
}

