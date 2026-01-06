#!/usr/bin/env bash
#
# checkpoint.sh - State persistence and checkpoints for claw
# Part of the TDD-driven autonomous execution system
#

set -euo pipefail

CHECKPOINTS_DIR=".claude/checkpoints"
SESSION_FILE=".claude/session.json"
MAX_CHECKPOINTS=5

# ============================================================================
# Checkpoint Creation
# ============================================================================

# Create a checkpoint of the current state
# Usage: create_checkpoint "name"
create_checkpoint() {
    local name="$1"

    mkdir -p "$CHECKPOINTS_DIR"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local checkpoint_file="$CHECKPOINTS_DIR/$name.json"

    # Gather state
    local queue_state="{}"
    [[ -f ".claude/queue.json" ]] && queue_state=$(cat .claude/queue.json)

    local git_commit=""
    local git_branch=""
    if git rev-parse --git-dir &>/dev/null; then
        git_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
        git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    fi

    if command -v jq &>/dev/null; then
        jq -n \
            --arg name "$name" \
            --arg timestamp "$timestamp" \
            --argjson queue "$queue_state" \
            --arg commit "$git_commit" \
            --arg branch "$git_branch" \
            '{
                name: $name,
                timestamp: $timestamp,
                queue: $queue,
                git: {commit: $commit, branch: $branch}
            }' > "$checkpoint_file"
    else
        echo "{\"name\": \"$name\", \"timestamp\": \"$timestamp\"}" > "$checkpoint_file"
    fi

    # Rotate old checkpoints
    _rotate_checkpoints

    echo "Checkpoint created: $name"
}

# Internal: Rotate checkpoints to keep only the last N
_rotate_checkpoints() {
    local count
    count=$(find "$CHECKPOINTS_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ $count -gt $MAX_CHECKPOINTS ]]; then
        # Delete oldest checkpoints
        find "$CHECKPOINTS_DIR" -name "*.json" -type f -print0 | \
            xargs -0 ls -t | \
            tail -n +$((MAX_CHECKPOINTS + 1)) | \
            xargs rm -f 2>/dev/null || true
    fi
}

# ============================================================================
# Checkpoint Restoration
# ============================================================================

# Restore a checkpoint
# Usage: restore_checkpoint "name" [--reset-git]
restore_checkpoint() {
    local name="$1"
    local reset_git=false

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --reset-git)
                reset_git=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local checkpoint_file="$CHECKPOINTS_DIR/$name.json"

    if [[ ! -f "$checkpoint_file" ]]; then
        echo "Checkpoint not found: $name"
        return 1
    fi

    if command -v jq &>/dev/null; then
        # Restore queue state
        local queue_state
        queue_state=$(jq '.queue' "$checkpoint_file")
        echo "$queue_state" > .claude/queue.json

        # Optionally reset git
        if $reset_git; then
            local commit
            commit=$(jq -r '.git.commit // empty' "$checkpoint_file")
            if [[ -n "$commit" ]]; then
                git reset --hard "$commit" 2>/dev/null || true
            fi
        fi
    fi

    echo "Checkpoint restored: $name"
}

# ============================================================================
# Checkpoint Listing
# ============================================================================

# List all checkpoints
# Usage: list_checkpoints [--count]
list_checkpoints() {
    local count_only=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --count)
                count_only=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ ! -d "$CHECKPOINTS_DIR" ]]; then
        if $count_only; then
            echo "0"
        else
            echo "No checkpoints found"
        fi
        return 0
    fi

    local files
    files=$(find "$CHECKPOINTS_DIR" -name "*.json" -type f 2>/dev/null)

    if [[ -z "$files" ]]; then
        if $count_only; then
            echo "0"
        else
            echo "No checkpoints found"
        fi
        return 0
    fi

    if $count_only; then
        echo "$files" | wc -l | tr -d ' '
    else
        for f in $files; do
            local name timestamp
            name=$(basename "$f" .json)
            if command -v jq &>/dev/null; then
                timestamp=$(jq -r '.timestamp // "unknown"' "$f")
                echo "$name ($timestamp)"
            else
                echo "$name"
            fi
        done
    fi
}

# ============================================================================
# Auto-Checkpoint
# ============================================================================

# Create an automatic checkpoint before risky operations
# Usage: auto_checkpoint "operation_name"
auto_checkpoint() {
    local operation="$1"
    create_checkpoint "auto-$operation"
}

# ============================================================================
# Session Persistence
# ============================================================================

# Save a session value
# Usage: save_session "key" "value"
save_session() {
    local key="$1"
    local value="$2"

    mkdir -p .claude

    # Initialize session file if it doesn't exist
    if [[ ! -f "$SESSION_FILE" ]]; then
        echo '{}' > "$SESSION_FILE"
    fi

    if command -v jq &>/dev/null; then
        jq --arg key "$key" --arg value "$value" \
            '.[$key] = $value' "$SESSION_FILE" > "$SESSION_FILE.tmp" \
            && mv "$SESSION_FILE.tmp" "$SESSION_FILE"
    fi
}

# Get a session value
# Usage: get_session "key"
get_session() {
    local key="$1"

    if [[ ! -f "$SESSION_FILE" ]]; then
        echo ""
        return 0
    fi

    if command -v jq &>/dev/null; then
        jq -r --arg key "$key" '.[$key] // ""' "$SESSION_FILE"
    else
        echo ""
    fi
}

# Clear all session data
# Usage: clear_session
clear_session() {
    rm -f "$SESSION_FILE"
}

