#!/usr/bin/env bash
#
# monitor.sh - Live terminal dashboard for claw autonomous execution
# Part of the TDD-driven autonomous execution system
#

set -euo pipefail

# Configuration
QUEUE_FILE=".claude/queue.json"
SESSION_FILE=".claude/session.json"
BLOCKER_HISTORY_FILE=".claude/blocker-history.json"
LOG_FILE=".claude/autonomous.log"
REFRESH_INTERVAL="${CLAW_MONITOR_REFRESH:-2}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# Spinner frames
SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
SPINNER_INDEX=0

# ============================================================================
# Display Helpers
# ============================================================================

# Clear screen and hide cursor
clear_screen() {
    clear
    printf '\033[?25l'  # Hide cursor
}

# Show cursor on exit
show_cursor() {
    printf '\033[?25h'  # Show cursor
}

# Cleanup function
cleanup() {
    show_cursor
    echo
    echo "Monitor stopped."
    exit 0
}

# Get next spinner frame
get_spinner() {
    local frame="${SPINNER_FRAMES[$SPINNER_INDEX]}"
    SPINNER_INDEX=$(( (SPINNER_INDEX + 1) % ${#SPINNER_FRAMES[@]} ))
    echo "$frame"
}

# Truncate string to max length
truncate() {
    local str="$1"
    local max="${2:-60}"
    if [[ ${#str} -gt $max ]]; then
        echo "${str:0:$((max-3))}..."
    else
        echo "$str"
    fi
}

# ============================================================================
# Status Display Functions
# ============================================================================

# Display header
display_header() {
    echo -e "${WHITE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                          🦞 CLAW MONITOR                               ║${NC}"
    echo -e "${WHITE}║                    Autonomous Execution Dashboard                       ║${NC}"
    echo -e "${WHITE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Display queue status
display_queue_status() {
    echo -e "${CYAN}┌─ Task Queue ────────────────────────────────────────────────────────────┐${NC}"

    if [[ ! -f "$QUEUE_FILE" ]]; then
        echo -e "${CYAN}│${NC} ${GRAY}No queue initialized. Run: /autonomous --init${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        return
    fi

    if ! command -v jq &>/dev/null; then
        echo -e "${CYAN}│${NC} ${RED}jq required for monitoring${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        return
    fi

    local queue_data
    queue_data=$(cat "$QUEUE_FILE")

    local pending running completed failed
    pending=$(echo "$queue_data" | jq '[.tasks[] | select(.status == "pending")] | length')
    running=$(echo "$queue_data" | jq '[.tasks[] | select(.status == "running")] | length')
    completed=$(echo "$queue_data" | jq '.completed | length')
    failed=$(echo "$queue_data" | jq '.failed | length')

    local total=$((pending + running + completed + failed))

    # Status indicator
    local status_icon status_text
    if [[ $running -gt 0 ]]; then
        status_icon=$(get_spinner)
        status_text="${GREEN}Running${NC}"
    elif [[ $pending -gt 0 ]]; then
        status_icon="⏳"
        status_text="${YELLOW}Pending${NC}"
    elif [[ $failed -gt 0 && $pending -eq 0 ]]; then
        status_icon="⚠️"
        status_text="${RED}Blocked${NC}"
    else
        status_icon="✅"
        status_text="${GREEN}Complete${NC}"
    fi

    echo -e "${CYAN}│${NC} Status:      $status_icon $status_text"
    echo -e "${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Pending:${NC}     ${YELLOW}$pending${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Running:${NC}     ${BLUE}$running${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Completed:${NC}   ${GREEN}$completed${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Failed:${NC}      ${RED}$failed${NC}"
    echo -e "${CYAN}│${NC}"

    # Progress bar
    if [[ $total -gt 0 ]]; then
        local progress=$(( (completed * 100) / total ))
        local filled=$(( progress / 5 ))
        local empty=$(( 20 - filled ))
        local bar=""
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=0; i<empty; i++)); do bar+="░"; done
        echo -e "${CYAN}│${NC} Progress:    [${GREEN}${bar}${NC}] ${progress}%"
    fi

    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Display current task
display_current_task() {
    echo -e "${YELLOW}┌─ Current Task ──────────────────────────────────────────────────────────┐${NC}"

    if [[ ! -f "$QUEUE_FILE" ]]; then
        echo -e "${YELLOW}│${NC} ${GRAY}No active task${NC}"
        echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        return
    fi

    local running_task
    running_task=$(jq -r '.tasks[] | select(.status == "running") | .description' "$QUEUE_FILE" 2>/dev/null | head -1)

    if [[ -n "$running_task" && "$running_task" != "null" ]]; then
        local task_id priority
        task_id=$(jq -r '.tasks[] | select(.status == "running") | .id' "$QUEUE_FILE" 2>/dev/null | head -1)
        priority=$(jq -r '.tasks[] | select(.status == "running") | .priority' "$QUEUE_FILE" 2>/dev/null | head -1)

        echo -e "${YELLOW}│${NC} $(get_spinner) $(truncate "$running_task" 60)"
        echo -e "${YELLOW}│${NC}   ID: ${GRAY}$task_id${NC}  Priority: ${WHITE}$priority${NC}"
    else
        # Show next pending task
        local next_task
        next_task=$(jq -r '[.tasks[] | select(.status == "pending")] | sort_by(if .priority == "high" then 0 elif .priority == "medium" then 1 else 2 end) | first | .description // empty' "$QUEUE_FILE" 2>/dev/null)

        if [[ -n "$next_task" ]]; then
            echo -e "${YELLOW}│${NC} ${GRAY}Next:${NC} $(truncate "$next_task" 60)"
        else
            echo -e "${YELLOW}│${NC} ${GRAY}No pending tasks${NC}"
        fi
    fi

    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Display blockers
display_blockers() {
    echo -e "${RED}┌─ Blockers ──────────────────────────────────────────────────────────────┐${NC}"

    if [[ ! -f "$BLOCKER_HISTORY_FILE" ]]; then
        echo -e "${RED}│${NC} ${GREEN}No blockers recorded${NC}"
        echo -e "${RED}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        return
    fi

    local blocker_count
    blocker_count=$(jq '.blockers | length' "$BLOCKER_HISTORY_FILE" 2>/dev/null || echo "0")

    if [[ $blocker_count -eq 0 ]]; then
        echo -e "${RED}│${NC} ${GREEN}No blockers recorded${NC}"
    else
        # Show recent blockers
        jq -r '.blockers | .[-3:] | reverse | .[] | "  \(.type): \(.details)"' "$BLOCKER_HISTORY_FILE" 2>/dev/null | while read -r line; do
            echo -e "${RED}│${NC}$line"
        done

        if [[ $blocker_count -gt 3 ]]; then
            echo -e "${RED}│${NC} ${GRAY}... and $((blocker_count - 3)) more${NC}"
        fi
    fi

    echo -e "${RED}└─────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Display recent activity
display_activity() {
    echo -e "${BLUE}┌─ Recent Activity ───────────────────────────────────────────────────────┐${NC}"

    if [[ -f "$LOG_FILE" ]]; then
        tail -n 6 "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
            echo -e "${BLUE}│${NC} $(truncate "$line" 70)"
        done
    else
        echo -e "${BLUE}│${NC} ${GRAY}No activity log found${NC}"
    fi

    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Display session info
display_session() {
    if [[ ! -f "$SESSION_FILE" ]]; then
        return
    fi

    echo -e "${PURPLE}┌─ Session ───────────────────────────────────────────────────────────────┐${NC}"

    local current_task progress
    current_task=$(jq -r '.current_task // empty' "$SESSION_FILE" 2>/dev/null)
    progress=$(jq -r '.progress // empty' "$SESSION_FILE" 2>/dev/null)

    [[ -n "$current_task" ]] && echo -e "${PURPLE}│${NC} Task: $current_task"
    [[ -n "$progress" ]] && echo -e "${PURPLE}│${NC} Progress: $progress"

    echo -e "${PURPLE}└─────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Display footer
display_footer() {
    echo
    echo -e "${GRAY}Controls: Ctrl+C to exit | Refreshes every ${REFRESH_INTERVAL}s | $(date '+%H:%M:%S')${NC}"
}

# ============================================================================
# Main Display
# ============================================================================

display_all() {
    clear_screen
    display_header
    display_queue_status
    echo
    display_current_task
    echo
    display_blockers
    echo
    display_activity
    display_session
    display_footer
}

# ============================================================================
# Monitor Commands
# ============================================================================

# Show status once (non-interactive)
show_status() {
    display_queue_status
    echo
    display_current_task
}

# Watch mode (interactive)
watch_mode() {
    trap cleanup SIGINT SIGTERM EXIT

    while true; do
        display_all
        sleep "$REFRESH_INTERVAL"
    done
}

# ============================================================================
# Entry Point
# ============================================================================

monitor_main() {
    local mode="${1:-watch}"

    case "$mode" in
        --status|-s)
            show_status
            ;;
        --watch|-w|watch)
            watch_mode
            ;;
        --help|-h)
            echo "Usage: monitor.sh [OPTIONS]"
            echo
            echo "Options:"
            echo "  --status, -s    Show current status and exit"
            echo "  --watch, -w     Live monitoring mode (default)"
            echo "  --help, -h      Show this help"
            echo
            echo "Environment:"
            echo "  CLAW_MONITOR_REFRESH  Refresh interval in seconds (default: 2)"
            ;;
        *)
            watch_mode
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    monitor_main "$@"
fi
