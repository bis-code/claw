#!/usr/bin/env bash
#
# utils.sh - Common utility functions for claw
#

set -euo pipefail

# ============================================================================
# Git Utilities
# ============================================================================

# Parse GitHub repository owner/name from various URL formats
# Supports:
#   - https://github.com/owner/repo.git
#   - https://github.com/owner/repo
#   - https://www.github.com/owner/repo.git
#   - git@github.com:owner/repo.git
#   - git@github.com:owner/repo
# Returns: owner/repo format, or empty string if not a valid GitHub URL
# Usage: parse_github_repo <url>
parse_github_repo() {
    local url="$1"
    local repo=""

    # Handle empty input
    if [[ -z "$url" ]]; then
        echo ""
        return 0
    fi

    # Handle HTTPS URLs (with or without www prefix)
    if [[ "$url" =~ github\.com/([^/]+)/([^/]+) ]]; then
        repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    # Handle SSH URLs
    elif [[ "$url" =~ github\.com:([^/]+)/([^/]+) ]]; then
        repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    fi

    # Remove .git suffix if present
    repo="${repo%.git}"

    echo "$repo"
}
