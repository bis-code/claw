#!/usr/bin/env bash
#
# Hook: Update project index after significant changes
# Runs on: PostToolUse (after file edits)
#
# This hook checks if the project index needs updating after file operations.

# Only run after file write operations
if [[ "$CLAUDE_TOOL_NAME" != "Write" ]] && [[ "$CLAUDE_TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

INDEX_FILE=".claude/project-index.json"

# If no index exists, skip (user hasn't run /index yet)
if [[ ! -f "$INDEX_FILE" ]]; then
    exit 0
fi

# Get index age in seconds
if [[ -f "$INDEX_FILE" ]]; then
    INDEX_AGE=$(($(date +%s) - $(stat -f %m "$INDEX_FILE" 2>/dev/null || stat -c %Y "$INDEX_FILE" 2>/dev/null)))

    # If index is older than 1 hour, mark it as stale
    if [[ $INDEX_AGE -gt 3600 ]]; then
        # Add stale marker
        if command -v jq &> /dev/null; then
            jq '.stale = true' "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
        fi
    fi
fi

exit 0
