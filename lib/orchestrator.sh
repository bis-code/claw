#!/usr/bin/env bash
#
# orchestrator.sh - External Claude Code orchestration
# Wraps Claude Code CLI with claw's prompts, rules, and context
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/home.sh"
source "$SCRIPT_DIR/output.sh"

# ============================================================================
# Claude Code Detection
# ============================================================================

# Check if Claude Code is available
# Usage: check_claude_cli
check_claude_cli() {
    if ! command -v claude &>/dev/null; then
        print_error "Claude Code CLI not found"
        echo "Install it from: https://claude.ai/code"
        return 1
    fi
    return 0
}

# Get Claude Code version
# Usage: get_claude_version
get_claude_version() {
    claude --version 2>/dev/null | head -1 || echo "unknown"
}

# ============================================================================
# Session Management
# ============================================================================

# Start a new Claude session with claw context
# Usage: start_session [--mode MODE] [--rules RULES...] [--prompt PROMPT]
start_session() {
    local mode="base"
    local rules=()
    local initial_prompt=""
    local working_dir="."

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode|-m)
                mode="$2"
                shift 2
                ;;
            --rules|-r)
                shift
                while [[ $# -gt 0 ]] && [[ "$1" != --* ]]; do
                    rules+=("$1")
                    shift
                done
                ;;
            --prompt|-p)
                initial_prompt="$2"
                shift 2
                ;;
            --dir|-d)
                working_dir="$2"
                shift 2
                ;;
            *)
                # Treat remaining as initial prompt
                initial_prompt="$*"
                break
                ;;
        esac
    done

    # Ensure claw is initialized
    if ! is_home_initialized; then
        print_warning "Claw not initialized. Running setup..."
        setup_claw_home
        echo ""
    fi

    # Check Claude CLI
    if ! check_claude_cli; then
        return 1
    fi

    # Build system prompt
    local system_prompt
    system_prompt=$(build_system_prompt --mode "$mode" --rules "${rules[@]}")

    # Create temp file for system prompt
    local prompt_file
    prompt_file=$(mktemp)
    echo "$system_prompt" > "$prompt_file"

    print_header "CLAW SESSION"
    print_kv "Mode" "$mode"
    print_kv "Rules" "${rules[*]:-none}"
    print_kv "Directory" "$working_dir"
    echo ""

    # Log session start
    local log_file="$CLAW_LOG_DIR/sessions.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting session: mode=$mode dir=$working_dir" >> "$log_file"

    # Start Claude with our context
    # Note: Claude Code doesn't support --system-prompt directly yet
    # So we inject context via the initial prompt or CLAUDE.md
    cd "$working_dir"

    if [[ -n "$initial_prompt" ]]; then
        # Pass initial prompt to Claude
        echo "$initial_prompt" | claude --print
    else
        # Interactive mode
        claude
    fi

    # Cleanup
    rm -f "$prompt_file"
}

# ============================================================================
# Autonomous Loop
# ============================================================================

# Status tracking
AUTO_STATUS_FILE="$CLAW_HOME/cache/auto-status.json"
AUTO_LOOP_ACTIVE=false

# Run autonomous development loop
# Usage: run_auto_loop [--hours N] [--max-iterations N] [--task TASK]
run_auto_loop() {
    local hours=4
    local max_iterations=50
    local task=""
    local working_dir="."

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --hours|-h)
                hours="$2"
                shift 2
                ;;
            --max-iterations|-n)
                max_iterations="$2"
                shift 2
                ;;
            --task|-t)
                task="$2"
                shift 2
                ;;
            --dir|-d)
                working_dir="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    # Ensure claw is initialized
    if ! is_home_initialized; then
        setup_claw_home
    fi

    # Check Claude CLI
    if ! check_claude_cli; then
        return 1
    fi

    # Calculate end time
    local start_time
    start_time=$(date +%s)
    local end_time=$((start_time + hours * 3600))

    # Initialize status
    _init_auto_status "$hours" "$max_iterations" "$task"

    print_header "CLAW AUTO MODE"
    print_kv "Hours" "$hours"
    print_kv "Max Iterations" "$max_iterations"
    print_kv "Task" "${task:-auto-discover}"
    print_kv "Directory" "$working_dir"
    echo ""

    AUTO_LOOP_ACTIVE=true
    trap _cleanup_auto_loop SIGINT SIGTERM

    local iteration=0
    local calls_made=0

    cd "$working_dir"

    while $AUTO_LOOP_ACTIVE; do
        # Check time limit
        local now
        now=$(date +%s)
        if [[ $now -ge $end_time ]]; then
            print_info "Time limit reached ($hours hours)"
            break
        fi

        # Check iteration limit
        if [[ $iteration -ge $max_iterations ]]; then
            print_info "Max iterations reached ($max_iterations)"
            break
        fi

        ((iteration++))
        _update_auto_status "$iteration" "$calls_made" "running"

        print_section "Iteration $iteration"

        # Build prompt for this iteration
        local prompt
        if [[ -n "$task" ]]; then
            prompt="Continue working on: $task

Current iteration: $iteration/$max_iterations
Time remaining: $(( (end_time - now) / 60 )) minutes

If task is complete, respond with: TASK_COMPLETE
If blocked, respond with: BLOCKED: <reason>
If need human input, respond with: NEED_INPUT: <question>"
        else
            prompt="You are in autonomous mode. Check for:
1. Open GitHub issues labeled 'claude-ready'
2. Failing tests to fix
3. TODO comments to address
4. Code improvements to make

Current iteration: $iteration/$max_iterations
Time remaining: $(( (end_time - now) / 60 )) minutes

Work on the highest priority item.
If all tasks complete, respond with: ALL_COMPLETE
If blocked, respond with: BLOCKED: <reason>"
        fi

        # Run Claude
        local output
        output=$(echo "$prompt" | claude --print 2>&1) || true
        ((calls_made++))

        # Check for completion/blocked signals
        if echo "$output" | grep -q "TASK_COMPLETE\|ALL_COMPLETE"; then
            print_success "Tasks completed!"
            break
        fi

        if echo "$output" | grep -q "BLOCKED:"; then
            local reason
            reason=$(echo "$output" | grep "BLOCKED:" | head -1)
            print_warning "$reason"
            _handle_blocker "$reason"
        fi

        if echo "$output" | grep -q "NEED_INPUT:"; then
            local question
            question=$(echo "$output" | grep "NEED_INPUT:" | head -1)
            print_warning "Human input needed: $question"
            _request_human_input "$question"
        fi

        # Rate limiting
        sleep 2

        print_section_end
        echo ""
    done

    _update_auto_status "$iteration" "$calls_made" "completed"
    _cleanup_auto_loop

    print_success "Auto loop finished"
    print_kv "Iterations" "$iteration"
    print_kv "API Calls" "$calls_made"
}

# Initialize auto status
_init_auto_status() {
    local hours="$1"
    local max_iterations="$2"
    local task="$3"

    mkdir -p "$(dirname "$AUTO_STATUS_FILE")"

    if command -v jq &>/dev/null; then
        jq -n \
            --arg hours "$hours" \
            --arg max "$max_iterations" \
            --arg task "$task" \
            --arg start "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
            '{
                hours: $hours,
                max_iterations: $max,
                task: $task,
                start_time: $start,
                iteration: 0,
                calls_made: 0,
                status: "starting"
            }' > "$AUTO_STATUS_FILE"
    fi
}

# Update auto status
_update_auto_status() {
    local iteration="$1"
    local calls_made="$2"
    local status="$3"

    if command -v jq &>/dev/null && [[ -f "$AUTO_STATUS_FILE" ]]; then
        jq \
            --arg iter "$iteration" \
            --arg calls "$calls_made" \
            --arg status "$status" \
            '.iteration = ($iter | tonumber) | .calls_made = ($calls | tonumber) | .status = $status' \
            "$AUTO_STATUS_FILE" > "$AUTO_STATUS_FILE.tmp" \
            && mv "$AUTO_STATUS_FILE.tmp" "$AUTO_STATUS_FILE"
    fi
}

# Handle a blocker
_handle_blocker() {
    local reason="$1"

    # Log blocker
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCKER: $reason" >> "$CLAW_LOG_DIR/auto.log"

    # Check if it's a recoverable blocker
    if echo "$reason" | grep -qi "rate limit"; then
        print_info "Rate limited. Waiting 60 seconds..."
        sleep 60
    elif echo "$reason" | grep -qi "network\|connection"; then
        print_info "Network issue. Waiting 10 seconds..."
        sleep 10
    else
        # Non-recoverable - stop the loop
        print_error "Non-recoverable blocker. Stopping."
        AUTO_LOOP_ACTIVE=false
    fi
}

# Request human input
_request_human_input() {
    local question="$1"

    # Create intervention request
    local request_file="$CLAW_HOME/cache/intervention-request.json"
    if command -v jq &>/dev/null; then
        jq -n \
            --arg question "$question" \
            --arg time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
            '{question: $question, timestamp: $time, resolved: false}' \
            > "$request_file"
    fi

    print_warning "Waiting for human response..."
    print_dim "Create ~/.claw/cache/intervention-response.json with your answer"

    # Wait for response (max 5 minutes)
    local response_file="$CLAW_HOME/cache/intervention-response.json"
    local waited=0
    while [[ $waited -lt 300 ]]; do
        if [[ -f "$response_file" ]]; then
            print_success "Response received"
            rm -f "$request_file" "$response_file"
            return 0
        fi
        sleep 5
        ((waited += 5))
    done

    print_error "Timeout waiting for human input"
    AUTO_LOOP_ACTIVE=false
}

# Cleanup auto loop
_cleanup_auto_loop() {
    AUTO_LOOP_ACTIVE=false
    _update_auto_status "0" "0" "stopped"
}

# ============================================================================
# Status Commands
# ============================================================================

# Show current auto status
# Usage: show_auto_status
show_auto_status() {
    if [[ ! -f "$AUTO_STATUS_FILE" ]]; then
        print_info "No auto session running"
        return 0
    fi

    if command -v jq &>/dev/null; then
        local status iteration calls
        status=$(jq -r '.status' "$AUTO_STATUS_FILE")
        iteration=$(jq -r '.iteration' "$AUTO_STATUS_FILE")
        calls=$(jq -r '.calls_made' "$AUTO_STATUS_FILE")

        print_section "Auto Status"
        print_kv "Status" "$status"
        print_kv "Iteration" "$iteration"
        print_kv "API Calls" "$calls"
        print_section_end
    else
        cat "$AUTO_STATUS_FILE"
    fi
}

# Stop running auto loop
# Usage: stop_auto_loop
stop_auto_loop() {
    if [[ -f "$AUTO_STATUS_FILE" ]]; then
        _update_auto_status "0" "0" "stopped"
        print_success "Auto loop stop requested"
    else
        print_info "No auto session to stop"
    fi
}
