#!/usr/bin/env bash
#
# wrapper.sh - Transparent Claude Code wrapper
# Preserves ALL Claude Code features while injecting claw context
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/home.sh"
source "$SCRIPT_DIR/output.sh" 2>/dev/null || true

# ============================================================================
# Configuration
# ============================================================================

CLAW_CONTEXT_FILE="$CLAW_HOME/cache/current-context.md"

# ============================================================================
# Context Injection
# ============================================================================

# Prepare context for Claude session
# This creates a temporary CLAUDE.md that Claude Code will read
# Usage: prepare_context [--mode MODE] [--rules RULES...]
prepare_context() {
    local mode="base"
    local rules=()
    local project_dir="."

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
            --dir|-d)
                project_dir="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    # Build the combined prompt
    local context=""

    # Add claw header
    context+="# CLAW Context (Auto-injected)"$'\n'
    context+="Mode: $mode | Rules: ${rules[*]:-default}"$'\n'
    context+=$'\n'

    # Add base prompt from ~/.claw
    if [[ -f "$CLAW_PROMPTS_DIR/base.md" ]]; then
        context+=$(cat "$CLAW_PROMPTS_DIR/base.md")
        context+=$'\n\n'
    fi

    # Add mode-specific prompt
    if [[ "$mode" != "base" ]] && [[ -f "$CLAW_PROMPTS_DIR/$mode.md" ]]; then
        context+="---"$'\n'
        context+="# $mode Mode"$'\n'
        context+=$(cat "$CLAW_PROMPTS_DIR/$mode.md")
        context+=$'\n\n'
    fi

    # Add selected rules
    if [[ ${#rules[@]} -gt 0 ]]; then
        for rule in "${rules[@]}"; do
            if [[ -f "$CLAW_RULES_DIR/$rule.md" ]]; then
                context+="---"$'\n'
                context+=$(cat "$CLAW_RULES_DIR/$rule.md")
                context+=$'\n\n'
            fi
        done
    fi

    # Save context for reference
    mkdir -p "$(dirname "$CLAW_CONTEXT_FILE")"
    echo "$context" > "$CLAW_CONTEXT_FILE"

    # Create/update CLAUDE.md in project directory
    # This is what Claude Code actually reads
    local project_claude_md="$project_dir/CLAUDE.md"

    if [[ -f "$project_claude_md" ]]; then
        # Backup existing CLAUDE.md
        cp "$project_claude_md" "$project_claude_md.bak"
    fi

    # Inject claw context at the top
    if [[ -f "$project_claude_md.bak" ]]; then
        # Prepend to existing content
        {
            echo "$context"
            echo "---"
            echo "# Project-Specific (from original CLAUDE.md)"
            echo ""
            cat "$project_claude_md.bak"
        } > "$project_claude_md"
    else
        echo "$context" > "$project_claude_md"
    fi

    echo "$project_claude_md"
}

# Cleanup injected context
# Usage: cleanup_context [project_dir]
cleanup_context() {
    local project_dir="${1:-.}"
    local project_claude_md="$project_dir/CLAUDE.md"

    if [[ -f "$project_claude_md.bak" ]]; then
        # Restore original CLAUDE.md
        mv "$project_claude_md.bak" "$project_claude_md"
    elif [[ -f "$project_claude_md" ]]; then
        # Remove injected CLAUDE.md if we created it
        rm "$project_claude_md"
    fi
}

# ============================================================================
# Transparent Wrapper
# ============================================================================

# Run Claude Code with claw context (transparent passthrough)
# All Claude features work: bypass permission, shift+tab, MCP, etc.
# Usage: run_claude [--mode MODE] [--rules RULES...] [CLAUDE_ARGS...]
run_claude() {
    local mode="base"
    local rules=()
    local project_dir="."
    local claude_args=()
    local cleanup_on_exit=true

    # Parse claw-specific args
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
            --dir|-d)
                project_dir="$2"
                shift 2
                ;;
            --no-cleanup)
                cleanup_on_exit=false
                shift
                ;;
            --)
                # Everything after -- goes to Claude
                shift
                claude_args+=("$@")
                break
                ;;
            *)
                # Pass unknown args to Claude
                claude_args+=("$1")
                shift
                ;;
        esac
    done

    # Ensure claw home exists
    if ! is_home_initialized; then
        setup_claw_home >/dev/null
    fi

    # Check Claude CLI
    if ! command -v claude &>/dev/null; then
        echo "Error: Claude Code CLI not found" >&2
        echo "Install from: https://claude.ai/code" >&2
        return 1
    fi

    # Prepare context (injects into project's CLAUDE.md)
    prepare_context --mode "$mode" --rules "${rules[@]}" --dir "$project_dir" >/dev/null

    # Setup cleanup trap
    if $cleanup_on_exit; then
        trap "cleanup_context '$project_dir'" EXIT INT TERM
    fi

    # Log session
    local log_file="$CLAW_LOG_DIR/sessions.log"
    mkdir -p "$CLAW_LOG_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] claw start: mode=$mode rules=${rules[*]:-} dir=$project_dir" >> "$log_file"

    # Run Claude Code directly - TRANSPARENT PASSTHROUGH
    # User gets ALL Claude features: bypass permission, shift+tab, MCP, etc.
    cd "$project_dir"
    exec claude "${claude_args[@]}"
}

# ============================================================================
# Non-Interactive Mode
# ============================================================================

# Run Claude with a single prompt and exit
# Usage: run_claude_once "prompt" [--mode MODE] [--rules RULES...]
run_claude_once() {
    local prompt=""
    local mode="base"
    local rules=()
    local project_dir="."

    # First positional arg is the prompt
    if [[ $# -gt 0 ]] && [[ "$1" != --* ]]; then
        prompt="$1"
        shift
    fi

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
            --dir|-d)
                project_dir="$2"
                shift 2
                ;;
            *)
                # Append to prompt
                prompt+=" $1"
                shift
                ;;
        esac
    done

    if [[ -z "$prompt" ]]; then
        echo "Error: No prompt provided" >&2
        return 1
    fi

    # Ensure claw home exists
    if ! is_home_initialized; then
        setup_claw_home >/dev/null
    fi

    # Prepare context
    prepare_context --mode "$mode" --rules "${rules[@]}" --dir "$project_dir" >/dev/null
    trap "cleanup_context '$project_dir'" EXIT INT TERM

    # Run Claude with the prompt
    cd "$project_dir"
    echo "$prompt" | claude --print
}

# ============================================================================
# Claw Commands (work alongside Claude)
# ============================================================================

# Show current claw configuration
show_claw_config() {
    echo "Claw Configuration"
    echo "=================="
    echo ""
    echo "Home: $CLAW_HOME"
    echo ""

    if [[ -f "$CLAW_CONFIG" ]]; then
        echo "Config:"
        cat "$CLAW_CONFIG" | jq . 2>/dev/null || cat "$CLAW_CONFIG"
    fi

    echo ""
    echo "Prompts:"
    ls -1 "$CLAW_PROMPTS_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  - /'

    echo ""
    echo "Rules:"
    ls -1 "$CLAW_RULES_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  - /'

    echo ""
    echo "Skills:"
    ls -1 "$CLAW_SKILLS_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  - /'
}

# Run a claw skill
# Usage: run_skill "skill-name" [ARGS...]
run_skill() {
    local skill_name="$1"
    shift || true

    local skill_file="$CLAW_SKILLS_DIR/$skill_name.md"

    if [[ ! -f "$skill_file" ]]; then
        echo "Error: Skill not found: $skill_name" >&2
        echo "Available skills:" >&2
        ls -1 "$CLAW_SKILLS_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  - /' >&2
        return 1
    fi

    # Read skill content and pass to Claude
    local skill_content
    skill_content=$(cat "$skill_file")

    # Run Claude with the skill as prompt
    run_claude_once "Execute this skill:

$skill_content

Arguments: $*" "$@"
}
