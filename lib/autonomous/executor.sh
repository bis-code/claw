#!/usr/bin/env bash
#
# executor.sh - Autonomous task executor for claw
# Part of the TDD-driven autonomous execution system
#

set -euo pipefail

QUEUE_FILE=".claude/queue.json"
LOG_FILE=".claude/autonomous.log"

# Get script directory for sourcing other libraries
LIB_DIR_EXECUTOR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${LIB_DIR_EXECUTOR}/utils.sh"

# ============================================================================
# Logging
# ============================================================================

# Log a message to the autonomous log file
# Usage: log_autonomous "message" [level]
log_autonomous() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p .claude
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# ============================================================================
# Task Queue Management
# ============================================================================

# Initialize an empty task queue
init_task_queue() {
    mkdir -p .claude
    echo '{"tasks": [], "completed": [], "failed": []}' > "$QUEUE_FILE"
    log_autonomous "Task queue initialized"
}

# Add a task to the queue
# Usage: add_task "description" "priority" [--github-issue NUMBER]
add_task() {
    local description="$1"
    local priority="${2:-medium}"
    local github_issue=""

    # Parse optional arguments
    shift 2 2>/dev/null || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --github-issue)
                github_issue="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    local id
    # Use UUID for unique task ID (uuidgen available on macOS and most Linux)
    if command -v uuidgen &>/dev/null; then
        id=$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -c1-8)
    else
        id=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | cut -c1-8 || echo "$$-$RANDOM" | shasum -a 256 | cut -c1-8)
    fi
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Read current queue
    local queue
    queue=$(cat "$QUEUE_FILE")

    # Create new task JSON with optional github_issue
    local new_task
    if [[ -n "$github_issue" ]]; then
        new_task="{\"id\": \"$id\", \"description\": \"$description\", \"priority\": \"$priority\", \"status\": \"pending\", \"created\": \"$timestamp\", \"github_issue\": $github_issue}"
    else
        new_task="{\"id\": \"$id\", \"description\": \"$description\", \"priority\": \"$priority\", \"status\": \"pending\", \"created\": \"$timestamp\"}"
    fi

    # Append task using jq if available, otherwise use sed
    if command -v jq &>/dev/null; then
        jq --argjson task "$new_task" '.tasks += [$task]' "$QUEUE_FILE" > "$QUEUE_FILE.tmp" && mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
    else
        # Fallback: simple string manipulation
        local tasks_content
        tasks_content=$(echo "$queue" | grep -o '"tasks": \[[^]]*\]' | sed 's/"tasks": \[//' | sed 's/\]$//')
        if [[ -z "$tasks_content" ]]; then
            tasks_content="$new_task"
        else
            tasks_content="$tasks_content, $new_task"
        fi
        echo "{\"tasks\": [$tasks_content], \"completed\": [], \"failed\": []}" > "$QUEUE_FILE"
    fi

    echo "$id"
}

# Get the next task (highest priority first)
# Usage: get_next_task [--id-only]
get_next_task() {
    local id_only=false
    [[ "${1:-}" == "--id-only" ]] && id_only=true

    if command -v jq &>/dev/null; then
        # Sort by priority: high > medium > low
        local task
        task=$(jq -r '
            .tasks
            | map(select(.status == "pending"))
            | sort_by(
                if .priority == "high" then 0
                elif .priority == "medium" then 1
                else 2
                end
            )
            | first
        ' "$QUEUE_FILE")

        if [[ "$task" == "null" ]] || [[ -z "$task" ]]; then
            return 0
        fi

        if $id_only; then
            echo "$task" | jq -r '.id'
        else
            echo "$task" | jq -r '.description'
        fi
    else
        # Fallback: just get first pending task (no priority sorting)
        grep -o '"description": "[^"]*"' "$QUEUE_FILE" | head -1 | sed 's/"description": "//' | sed 's/"$//'
    fi
}

# Complete a task by moving it from tasks to completed
# Usage: complete_task "task_id"
complete_task() {
    local task_id="$1"

    if command -v jq &>/dev/null; then
        local timestamp
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        jq --arg id "$task_id" --arg ts "$timestamp" '
            (.tasks[] | select(.id == $id)) as $task |
            if $task then
                .completed += [$task | .status = "completed" | .completed_at = $ts] |
                .tasks = [.tasks[] | select(.id != $id)]
            else
                .
            end
        ' "$QUEUE_FILE" > "$QUEUE_FILE.tmp" && mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
    else
        echo "complete_task requires jq" >&2
        return 1
    fi
}

# Execute a task command and return the result
# Usage: execute_task "command"
execute_task() {
    local cmd="$1"
    local exit_code=0

    # Execute the command in a subshell, capturing output and exit code
    set +e
    ( eval "$cmd" )
    exit_code=$?
    set -e

    return $exit_code
}

# Run the execution loop until queue is empty or conditions are met
# Usage: run_loop [--max-iterations N] [--stop-on-failure]
run_loop() {
    local max_iterations=0
    local stop_on_failure=false
    local iterations=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max-iterations)
                max_iterations="$2"
                shift 2
                ;;
            --stop-on-failure)
                stop_on_failure=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    while true; do
        # Check max iterations
        if [[ $max_iterations -gt 0 ]] && [[ $iterations -ge $max_iterations ]]; then
            echo "Max iterations reached"
            return 0
        fi

        # Get next task
        local task_desc
        task_desc=$(get_next_task)

        # If no more tasks, we're done
        if [[ -z "$task_desc" ]] || [[ "$task_desc" == "null" ]]; then
            return 0
        fi

        local task_id
        task_id=$(get_next_task --id-only)

        # Safety check for task_id
        if [[ -z "$task_id" ]] || [[ "$task_id" == "null" ]]; then
            return 0
        fi

        # Execute the task
        log_autonomous "Starting task: $task_desc" "INFO"
        local exit_code=0
        set +e
        execute_task "$task_desc"
        exit_code=$?
        set -e

        if [[ $exit_code -ne 0 ]]; then
            log_autonomous "Task failed: $task_desc (exit code: $exit_code)" "ERROR"
            if $stop_on_failure; then
                echo "BLOCKED: Task failed with exit code $exit_code"
                return 1
            fi
            # Mark as failed and continue
            fail_task "$task_id"
        else
            log_autonomous "Task completed: $task_desc" "INFO"
            complete_task "$task_id"
        fi

        ((iterations++)) || true
    done
}

# Mark a task as failed
# Usage: fail_task "task_id"
fail_task() {
    local task_id="$1"

    if command -v jq &>/dev/null; then
        local timestamp
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        jq --arg id "$task_id" --arg ts "$timestamp" '
            (.tasks[] | select(.id == $id)) as $task |
            if $task then
                .failed += [$task | .status = "failed" | .failed_at = $ts] |
                .tasks = [.tasks[] | select(.id != $id)]
            else
                .
            end
        ' "$QUEUE_FILE" > "$QUEUE_FILE.tmp" && mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
    else
        echo "fail_task requires jq" >&2
        return 1
    fi
}

# Get the state of a task by ID
# Usage: get_task_state "task_id"
get_task_state() {
    local task_id="$1"

    if command -v jq &>/dev/null; then
        # Check in tasks array first
        local state
        state=$(jq -r --arg id "$task_id" '
            (.tasks[] | select(.id == $id) | .status) //
            (.completed[] | select(.id == $id) | .status) //
            (.failed[] | select(.id == $id) | .status) //
            "unknown"
        ' "$QUEUE_FILE")
        echo "$state"
    else
        echo "get_task_state requires jq" >&2
        return 1
    fi
}

# Mark a task as running
# Usage: start_task "task_id"
start_task() {
    local task_id="$1"

    if command -v jq &>/dev/null; then
        jq --arg id "$task_id" '
            .tasks = [.tasks[] | if .id == $id then .status = "running" else . end]
        ' "$QUEUE_FILE" > "$QUEUE_FILE.tmp" && mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
    else
        echo "start_task requires jq" >&2
        return 1
    fi
}

# Get task history (completed and failed tasks)
# Usage: get_task_history
get_task_history() {
    if command -v jq &>/dev/null; then
        jq -r '
            (.completed[] | "\(.description) - \(.status)"),
            (.failed[] | "\(.description) - \(.status)")
        ' "$QUEUE_FILE" 2>/dev/null || true
    else
        echo "get_task_history requires jq" >&2
        return 1
    fi
}

# Import issues from GitHub into the task queue
# Usage: import_from_github [--repo OWNER/REPO] [--label LABEL] [--state STATE] [--all-repos]
import_from_github() {
    local repo=""
    local label=""
    local state="open"
    local all_repos=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo)
                repo="$2"
                shift 2
                ;;
            --label)
                label="$2"
                shift 2
                ;;
            --state)
                state="$2"
                shift 2
                ;;
            --all-repos)
                all_repos=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Check for gh CLI
    if ! command -v gh &>/dev/null; then
        echo "import_from_github requires gh CLI" >&2
        return 1
    fi

    local count=0

    # Multi-repo mode: fetch from all tracked repos via claw
    if $all_repos; then
        # Try to use claw issues command if available
        local issues
        local claw_args=("--json")
        [[ -n "$label" ]] && claw_args+=("--label" "$label")
        [[ -n "$state" ]] && claw_args+=("--state" "$state")

        # Check if claw is available
        if command -v claw &>/dev/null; then
            issues=$(claw issues "${claw_args[@]}" 2>/dev/null) || issues="[]"
        else
            # Fallback: just fetch from current repo
            local remote_url
            remote_url=$(git remote get-url origin 2>/dev/null) || remote_url=""
            local current_repo
            current_repo=$(parse_github_repo "$remote_url")
            if [[ -n "$current_repo" ]]; then
                local gh_args=("issue" "list" "--repo" "$current_repo" "--json" "number,title,labels,body,repository" "--state" "$state")
                [[ -n "$label" ]] && gh_args+=("--label" "$label")
                issues=$(gh "${gh_args[@]}" 2>/dev/null) || issues="[]"
            else
                issues="[]"
            fi
        fi

        # Add each issue as a task
        if command -v jq &>/dev/null; then
            while IFS= read -r issue; do
                local number title issue_repo
                number=$(echo "$issue" | jq -r '.number')
                title=$(echo "$issue" | jq -r '.title')
                issue_repo=$(echo "$issue" | jq -r '.repository.nameWithOwner // empty')

                if [[ -n "$number" && "$number" != "null" ]]; then
                    # Include repo in task description for multi-repo context
                    local task_desc="$title"
                    [[ -n "$issue_repo" ]] && task_desc="[$issue_repo] $title"
                    add_task "$task_desc" "medium" --github-issue "$number" >/dev/null
                    ((count++)) || true
                fi
            done < <(echo "$issues" | jq -c '.[]')
        fi

        echo "Imported $count issues from tracked repos"
        return 0
    fi

    # Single repo mode (original behavior)
    local gh_args=("issue" "list" "--json" "number,title,labels,body" "--state" "$state")
    [[ -n "$repo" ]] && gh_args+=("--repo" "$repo")
    [[ -n "$label" ]] && gh_args+=("--label" "$label")

    # Fetch issues
    local issues
    issues=$(gh "${gh_args[@]}" 2>/dev/null) || {
        echo "Failed to fetch issues from GitHub" >&2
        return 1
    }

    # Add each issue as a task
    if command -v jq &>/dev/null; then
        while IFS= read -r issue; do
            local number title
            number=$(echo "$issue" | jq -r '.number')
            title=$(echo "$issue" | jq -r '.title')

            if [[ -n "$number" && "$number" != "null" ]]; then
                add_task "$title" "medium" --github-issue "$number" >/dev/null
                ((count++)) || true
            fi
        done < <(echo "$issues" | jq -c '.[]')
    fi

    echo "Imported $count issues from GitHub"
}
