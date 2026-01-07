#!/usr/bin/env bash
#
# repos.sh - Multi-repo tracking for claw
# Manages a list of GitHub repos to aggregate across
#

set -euo pipefail

CLAW_HOME="${CLAW_HOME:-$HOME/.claw}"
REPOS_FILE="$CLAW_HOME/repos.json"

# ============================================================================
# Validation
# ============================================================================

# Validate repo format (owner/repo)
# Usage: validate_repo "owner/repo"
validate_repo() {
    local repo="$1"

    # Trim whitespace
    repo=$(echo "$repo" | xargs)

    # Must contain exactly one slash
    if [[ ! "$repo" =~ ^[^/]+/[^/]+$ ]]; then
        echo "Invalid format: '$repo'. Expected: owner/repo" >&2
        return 1
    fi

    # Extract owner and repo
    local owner="${repo%%/*}"
    local name="${repo##*/}"

    # Neither can be empty
    if [[ -z "$owner" ]] || [[ -z "$name" ]]; then
        echo "Invalid format: '$repo'. Owner and repo name cannot be empty" >&2
        return 1
    fi

    echo "$repo"
    return 0
}

# ============================================================================
# Core Functions
# ============================================================================

# Initialize repos file if needed
init_repos_file() {
    mkdir -p "$CLAW_HOME"
    if [[ ! -f "$REPOS_FILE" ]]; then
        echo '{"repos": []}' > "$REPOS_FILE"
    fi

    # Validate JSON, reset if corrupted
    if ! jq . "$REPOS_FILE" &>/dev/null; then
        echo '{"repos": []}' > "$REPOS_FILE"
    fi
}

# Add a repo to track
# Usage: repos_add "owner/repo"
repos_add() {
    local input="$1"

    # Validate and normalize
    local repo
    repo=$(validate_repo "$input") || return 1

    init_repos_file

    # Check if already tracked
    if jq -e --arg r "$repo" '.repos | index($r)' "$REPOS_FILE" &>/dev/null; then
        echo "Already tracking: $repo"
        return 0
    fi

    # Add to list
    jq --arg r "$repo" '.repos += [$r]' "$REPOS_FILE" > "$REPOS_FILE.tmp" \
        && mv "$REPOS_FILE.tmp" "$REPOS_FILE"

    echo "Added: $repo"
}

# Remove a repo from tracking
# Usage: repos_remove "owner/repo"
repos_remove() {
    local input="$1"

    # Validate and normalize
    local repo
    repo=$(validate_repo "$input") || return 1

    init_repos_file

    # Check if tracked
    if ! jq -e --arg r "$repo" '.repos | index($r)' "$REPOS_FILE" &>/dev/null; then
        echo "Repo not tracked: $repo"
        return 0
    fi

    # Remove from list
    jq --arg r "$repo" '.repos = [.repos[] | select(. != $r)]' "$REPOS_FILE" > "$REPOS_FILE.tmp" \
        && mv "$REPOS_FILE.tmp" "$REPOS_FILE"

    echo "Removed: $repo"
}

# List all tracked repos
# Usage: repos_list
repos_list() {
    init_repos_file

    local count
    count=$(jq '.repos | length' "$REPOS_FILE")

    if [[ "$count" -eq 0 ]]; then
        echo "No repos tracked"
        echo ""
        echo "Add repos with: claw repos add owner/repo"
        return 0
    fi

    echo "Tracked repos ($count):"
    jq -r '.repos[]' "$REPOS_FILE" | while read -r repo; do
        echo "  - $repo"
    done
}

# Clear all tracked repos
# Usage: repos_clear
repos_clear() {
    init_repos_file
    echo '{"repos": []}' > "$REPOS_FILE"
    echo "Cleared all tracked repos"
}

# ============================================================================
# Query Functions (for commands to use)
# ============================================================================

# Get list of tracked repos (one per line)
# Usage: get_tracked_repos
get_tracked_repos() {
    init_repos_file
    jq -r '.repos[]' "$REPOS_FILE" 2>/dev/null || true
}

# Get current directory's repo (from git remote)
# Usage: get_current_repo
get_current_repo() {
    if ! git rev-parse --git-dir &>/dev/null; then
        return 0
    fi

    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null) || return 0

    # Extract owner/repo from various URL formats
    # https://github.com/owner/repo.git
    # git@github.com:owner/repo.git
    # https://github.com/owner/repo
    local repo=""

    # Handle HTTPS URLs
    if [[ "$remote_url" =~ github\.com/([^/]+)/([^/]+) ]]; then
        repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    # Handle SSH URLs
    elif [[ "$remote_url" =~ github\.com:([^/]+)/([^/]+) ]]; then
        repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    fi

    # Remove .git suffix if present
    repo="${repo%.git}"

    if [[ -n "$repo" ]] && [[ "$repo" =~ ^[^/]+/[^/]+$ ]]; then
        echo "$repo"
    fi
}

# Get all repos (tracked + current directory, deduplicated)
# Usage: get_all_repos
get_all_repos() {
    local repos=()

    # Get current repo first (priority)
    local current
    current=$(get_current_repo)
    if [[ -n "$current" ]]; then
        repos+=("$current")
    fi

    # Add tracked repos (excluding current to avoid duplicates)
    while IFS= read -r repo; do
        if [[ -n "$repo" ]] && [[ "$repo" != "$current" ]]; then
            repos+=("$repo")
        fi
    done < <(get_tracked_repos)

    # Output
    for repo in "${repos[@]}"; do
        echo "$repo"
    done
}

# ============================================================================
# GitHub Integration
# ============================================================================

# Fetch issues from all repos
# Usage: fetch_all_issues [--label LABEL] [--state STATE]
fetch_all_issues() {
    local label=""
    local state="open"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --label|-l)
                label="$2"
                shift 2
                ;;
            --state|-s)
                state="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    # Check gh CLI
    if ! command -v gh &>/dev/null; then
        echo "Error: gh CLI not found" >&2
        return 1
    fi

    local all_issues="[]"

    # Fetch from each repo
    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue

        local gh_args=("issue" "list" "--repo" "$repo" "--json" "number,title,labels,repository" "--state" "$state")
        [[ -n "$label" ]] && gh_args+=("--label" "$label")

        local issues
        issues=$(gh "${gh_args[@]}" 2>/dev/null) || continue

        # Merge into all_issues
        all_issues=$(echo "$all_issues $issues" | jq -s 'add')
    done < <(get_all_repos)

    echo "$all_issues"
}

# Show issues summary from all repos
# Usage: show_issues_summary [--label LABEL] [--json]
show_issues_summary() {
    local label=""
    local state="open"
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --label|-l)
                label="$2"
                shift 2
                ;;
            --state|-s)
                state="$2"
                shift 2
                ;;
            --json|-j)
                json_output=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local issues
    local args=()
    [[ -n "$label" ]] && args+=(--label "$label")
    [[ -n "$state" ]] && args+=(--state "$state")

    # JSON mode: just output raw JSON
    if [[ "$json_output" == "true" ]]; then
        fetch_all_issues "${args[@]}"
        return 0
    fi

    echo "Fetching issues from tracked repos..."
    echo ""

    issues=$(fetch_all_issues "${args[@]}")

    local count
    count=$(echo "$issues" | jq 'length')

    if [[ "$count" -eq 0 ]]; then
        echo "No issues found"
        return 0
    fi

    echo "Found $count issues:"
    echo ""

    # Group by repo
    echo "$issues" | jq -r 'group_by(.repository.nameWithOwner) | .[] |
        "## " + .[0].repository.nameWithOwner + "\n" +
        (. | map("  #" + (.number|tostring) + " " + .title) | join("\n"))' 2>/dev/null || \
    echo "$issues" | jq -r '.[] | "#" + (.number|tostring) + " " + .title'
}
