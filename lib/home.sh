#!/usr/bin/env bash
#
# home.sh - Claw home directory management (~/.claw)
# External orchestrator architecture - keeps prompts/rules outside user's project
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

CLAW_HOME="${CLAW_HOME:-$HOME/.claw}"
CLAW_CONFIG="$CLAW_HOME/config.json"
CLAW_PROMPTS_DIR="$CLAW_HOME/prompts"
CLAW_RULES_DIR="$CLAW_HOME/rules"
CLAW_SKILLS_DIR="$CLAW_HOME/skills"
CLAW_CACHE_DIR="$CLAW_HOME/cache"
CLAW_LOG_DIR="$CLAW_HOME/logs"

# ============================================================================
# Home Directory Setup
# ============================================================================

# Check if claw home is initialized
# Usage: is_home_initialized
is_home_initialized() {
    [[ -d "$CLAW_HOME" ]] && [[ -f "$CLAW_CONFIG" ]]
}

# Initialize claw home directory
# Usage: init_claw_home [--force]
init_claw_home() {
    local force=false
    [[ "${1:-}" == "--force" ]] && force=true

    if is_home_initialized && ! $force; then
        echo "Claw home already initialized at $CLAW_HOME"
        echo "Use --force to reinitialize"
        return 0
    fi

    echo "Initializing claw home at $CLAW_HOME..."

    # Create directory structure
    mkdir -p "$CLAW_PROMPTS_DIR"
    mkdir -p "$CLAW_RULES_DIR"
    mkdir -p "$CLAW_SKILLS_DIR"
    mkdir -p "$CLAW_CACHE_DIR"
    mkdir -p "$CLAW_LOG_DIR"

    # Create default config
    cat > "$CLAW_CONFIG" << 'EOF'
{
  "version": "0.5.0",
  "defaults": {
    "preset": "base",
    "auto_index": true,
    "tdd_mode": true
  },
  "autonomous": {
    "max_iterations": 50,
    "stop_on_failure": false,
    "checkpoint_before_task": true
  },
  "rate_limits": {
    "max_calls_per_hour": 100,
    "cooldown_seconds": 60
  }
}
EOF

    echo "Created config at $CLAW_CONFIG"
}

# Get claw home path
# Usage: get_claw_home
get_claw_home() {
    echo "$CLAW_HOME"
}

# ============================================================================
# Prompt Management
# ============================================================================

# Install default prompts
# Usage: install_default_prompts
install_default_prompts() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local templates_dir="${script_dir}/../templates"

    echo "Installing prompts..."

    # Copy CLAUDE.md as base prompt
    if [[ -f "$templates_dir/CLAUDE.md" ]]; then
        cp "$templates_dir/CLAUDE.md" "$CLAW_PROMPTS_DIR/base.md"
        echo "  - base.md (core system prompt)"
    fi

    # Create TDD prompt
    cat > "$CLAW_PROMPTS_DIR/tdd.md" << 'EOF'
# TDD Mode

You are in strict TDD mode. Follow these rules:

1. **NEVER write production code without tests first**
2. Run tests after every change
3. Fix failures before proceeding
4. One logical change per commit

## Workflow
1. Write failing test (Red)
2. Write minimal code to pass (Green)
3. Refactor if needed
4. Commit

## Absolute Prohibitions
- Writing code without tests
- Asking user to "verify manually"
- Skipping tests "to save time"
EOF
    echo "  - tdd.md (TDD mode prompt)"

    # Create autonomous prompt
    cat > "$CLAW_PROMPTS_DIR/autonomous.md" << 'EOF'
# Autonomous Mode

You are operating in autonomous mode with:
- Task queue management
- Automatic test feedback loops
- Blocker detection and resolution
- Checkpoint/rollback capability

## Behavior
- Execute tasks from queue in priority order
- Run tests after each change
- Retry on transient failures (max 3 times)
- Create checkpoints before risky operations
- Request human help for fatal blockers (permissions, auth)

## Auto-Resolution
- Missing dependency → install it
- Rate limit → wait and retry
- Network error → retry after delay

## Reporting
Log all activity to ~/.claw/logs/autonomous.log
EOF
    echo "  - autonomous.md (autonomous mode prompt)"
}

# ============================================================================
# Rules Management
# ============================================================================

# Install default rules
# Usage: install_default_rules
install_default_rules() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local templates_dir="${script_dir}/../templates/.claude/rules"

    echo "Installing rules..."

    if [[ -d "$templates_dir" ]]; then
        for rule_file in "$templates_dir"/*.md; do
            if [[ -f "$rule_file" ]]; then
                local name
                name=$(basename "$rule_file")
                cp "$rule_file" "$CLAW_RULES_DIR/$name"
                echo "  - $name"
            fi
        done
    fi
}

# ============================================================================
# Skills Management
# ============================================================================

# Install default skills
# Usage: install_default_skills
install_default_skills() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local templates_dir="${script_dir}/../templates/.claude/commands"

    echo "Installing skills..."

    if [[ -d "$templates_dir" ]]; then
        for skill_file in "$templates_dir"/*.md; do
            if [[ -f "$skill_file" ]]; then
                local name
                name=$(basename "$skill_file")
                cp "$skill_file" "$CLAW_SKILLS_DIR/$name"
                echo "  - $name"
            fi
        done
    fi
}

# ============================================================================
# Full Setup
# ============================================================================

# Full claw home setup
# Usage: setup_claw_home [--force]
setup_claw_home() {
    local force="${1:-}"

    init_claw_home "$force"
    echo ""
    install_default_prompts
    echo ""
    install_default_rules
    echo ""
    install_default_skills
    echo ""
    echo "Claw home setup complete at $CLAW_HOME"
}

# ============================================================================
# Config Access
# ============================================================================

# Get config value
# Usage: get_config "key.subkey"
get_config() {
    local key="$1"

    if [[ ! -f "$CLAW_CONFIG" ]]; then
        echo ""
        return 1
    fi

    if command -v jq &>/dev/null; then
        jq -r ".$key // empty" "$CLAW_CONFIG"
    else
        echo ""
    fi
}

# Set config value
# Usage: set_config "key" "value"
set_config() {
    local key="$1"
    local value="$2"

    if [[ ! -f "$CLAW_CONFIG" ]]; then
        echo "{}" > "$CLAW_CONFIG"
    fi

    if command -v jq &>/dev/null; then
        jq --arg key "$key" --arg value "$value" \
            '.[$key] = $value' "$CLAW_CONFIG" > "$CLAW_CONFIG.tmp" \
            && mv "$CLAW_CONFIG.tmp" "$CLAW_CONFIG"
    fi
}

# ============================================================================
# Prompt Building
# ============================================================================

# Build combined system prompt for Claude
# Usage: build_system_prompt [--mode MODE] [--rules RULES...]
build_system_prompt() {
    local mode="base"
    local rules=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                mode="$2"
                shift 2
                ;;
            --rules)
                shift
                while [[ $# -gt 0 ]] && [[ "$1" != --* ]]; do
                    rules+=("$1")
                    shift
                done
                ;;
            *)
                shift
                ;;
        esac
    done

    # Start with base prompt
    local prompt=""
    if [[ -f "$CLAW_PROMPTS_DIR/base.md" ]]; then
        prompt+=$(cat "$CLAW_PROMPTS_DIR/base.md")
        prompt+=$'\n\n'
    fi

    # Add mode-specific prompt
    if [[ "$mode" != "base" ]] && [[ -f "$CLAW_PROMPTS_DIR/$mode.md" ]]; then
        prompt+=$(cat "$CLAW_PROMPTS_DIR/$mode.md")
        prompt+=$'\n\n'
    fi

    # Add requested rules
    for rule in "${rules[@]}"; do
        if [[ -f "$CLAW_RULES_DIR/$rule.md" ]]; then
            prompt+="---"$'\n'
            prompt+=$(cat "$CLAW_RULES_DIR/$rule.md")
            prompt+=$'\n\n'
        fi
    done

    echo "$prompt"
}

# List available prompts
# Usage: list_prompts
list_prompts() {
    echo "Available prompts:"
    for f in "$CLAW_PROMPTS_DIR"/*.md; do
        [[ -f "$f" ]] && echo "  - $(basename "$f" .md)"
    done
}

# List available rules
# Usage: list_rules
list_rules() {
    echo "Available rules:"
    for f in "$CLAW_RULES_DIR"/*.md; do
        [[ -f "$f" ]] && echo "  - $(basename "$f" .md)"
    done
}

# List available skills
# Usage: list_skills
list_skills() {
    echo "Available skills:"
    for f in "$CLAW_SKILLS_DIR"/*.md; do
        [[ -f "$f" ]] && echo "  - $(basename "$f" .md)"
    done
}
