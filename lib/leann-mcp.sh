#!/usr/bin/env bash
# leann-mcp.sh - Auto-install and configure leann MCP server for Claude Code
#
# This module handles:
# - Detection of leann installation
# - Detection of leann MCP configuration
# - Installation via uv/pipx
# - MCP server configuration
# - Progress display during setup

# Only set strict mode when running as script (not when sourced for tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

# Use CLAW_HOME from environment or default
CLAW_HOME="${CLAW_HOME:-$HOME/.claw}"

# ============================================================================
# Colors (for progress display)
# ============================================================================

if [[ -t 1 ]]; then
    CYAN=$'\033[0;36m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[0;33m'
    RED=$'\033[0;31m'
    GRAY=$'\033[0;90m'
    BOLD=$'\033[1m'
    NC=$'\033[0m'
else
    CYAN='' GREEN='' YELLOW='' RED='' GRAY='' BOLD='' NC=''
fi

# ============================================================================
# Detection Functions
# ============================================================================

# Check if leann command is installed
is_leann_installed() {
    command -v leann &>/dev/null
}

# Check if leann MCP server is configured in Claude Code
is_leann_mcp_configured() {
    # Check if claude mcp list shows leann-server
    if command -v claude &>/dev/null; then
        claude mcp list 2>/dev/null | grep -q "leann-server" && return 0
    fi
    return 1
}

# Check if first-run leann setup is complete
is_leann_setup_complete() {
    [[ -f "$CLAW_HOME/.leann-mcp-configured" ]]
}

# Mark leann setup as complete
mark_leann_setup_complete() {
    mkdir -p "$CLAW_HOME"
    touch "$CLAW_HOME/.leann-mcp-configured"
}

# ============================================================================
# Progress Display (Claude-like spinner)
# ============================================================================

# Spinner characters for animation
SPINNER_CHARS=("✶" "✸" "✹" "✺" "✹" "✸")
SPINNER_IDX=0
START_TIME=""
CURRENT_STEP=""
SPINNER_PID=""

# Start the spinner in background
start_spinner() {
    local message="$1"
    START_TIME=$(date +%s)
    CURRENT_STEP="$message"

    # Don't start spinner if not interactive
    [[ ! -t 1 ]] && return

    # Save cursor position and hide cursor
    printf "\033[?25l"

    # Start background spinner
    (
        while true; do
            local elapsed=$(($(date +%s) - START_TIME))
            local mins=$((elapsed / 60))
            local secs=$((elapsed % 60))
            local time_str
            if [[ $mins -gt 0 ]]; then
                time_str="${mins}m ${secs}s"
            else
                time_str="${secs}s"
            fi

            local char="${SPINNER_CHARS[$((SPINNER_IDX % ${#SPINNER_CHARS[@]}))]}"
            SPINNER_IDX=$((SPINNER_IDX + 1))

            # Clear line and print status
            printf "\r\033[K${CYAN}%s${NC} ${BOLD}%s${NC}${GRAY} (%s)${NC}" "$char" "$CURRENT_STEP" "$time_str"

            sleep 0.15
        done
    ) &
    SPINNER_PID=$!
}

# Update spinner message
update_spinner() {
    local message="$1"
    CURRENT_STEP="$message"
}

# Stop spinner and show final status
stop_spinner() {
    local status="$1"  # success, error
    local message="${2:-$CURRENT_STEP}"

    # Kill background spinner if running
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        SPINNER_PID=""
    fi

    # Show cursor
    printf "\033[?25h"

    # Clear line and show final status
    printf "\r\033[K"

    if [[ "$status" == "success" ]]; then
        printf "${GREEN}✓${NC} ${BOLD}%s${NC}\n" "$message"
    else
        printf "${RED}✗${NC} ${BOLD}%s${NC}\n" "$message"
    fi
}

# Cleanup spinner on exit
cleanup_spinner() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        printf "\033[?25h"  # Show cursor
    fi
}

# Only set trap if not being sourced for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap cleanup_spinner EXIT
fi

# Show setup progress message with spinner-like prefix (simple version)
show_setup_progress() {
    local message="$1"
    printf "${CYAN}✶${NC} ${BOLD}%s${NC}\n" "$message"
}

# Show a setup step with status icon
show_setup_step() {
    local status="$1"
    local message="$2"

    case "$status" in
        pending)
            printf "  ${GRAY}○${NC} %s\n" "$message"
            ;;
        running)
            printf "  ${YELLOW}◐${NC} %s${GRAY}...${NC}\n" "$message"
            ;;
        done)
            printf "  ${GREEN}✓${NC} %s\n" "$message"
            ;;
        error)
            printf "  ${RED}✗${NC} %s\n" "$message"
            ;;
    esac
}

# Show final status box
show_setup_complete() {
    echo ""
    printf "${GREEN}╭───────────────────────────────────────╮${NC}\n"
    printf "${GREEN}│${NC} ${BOLD}Leann MCP configured successfully!${NC}  ${GREEN}│${NC}\n"
    printf "${GREEN}│${NC} ${GRAY}Semantic code search is now enabled.${NC}${GREEN}│${NC}\n"
    printf "${GREEN}╰───────────────────────────────────────╯${NC}\n"
    echo ""
}

# ============================================================================
# Installation Functions
# ============================================================================

# Install leann using available package manager
install_leann() {
    # Try uv first (recommended)
    if command -v uv &>/dev/null; then
        show_setup_step "running" "Installing leann via uv"
        if uv tool install leann-core --with leann &>/dev/null; then
            show_setup_step "done" "Leann installed via uv"
            return 0
        fi
    fi

    # Try pipx next
    if command -v pipx &>/dev/null; then
        show_setup_step "running" "Installing leann via pipx"
        if pipx install leann-core &>/dev/null; then
            show_setup_step "done" "Leann installed via pipx"
            return 0
        fi
    fi

    # Try pip as last resort
    if command -v pip &>/dev/null; then
        show_setup_step "running" "Installing leann via pip"
        if pip install --user leann-core &>/dev/null; then
            show_setup_step "done" "Leann installed via pip"
            return 0
        fi
    fi

    show_setup_step "error" "No package manager found (need uv, pipx, or pip)"
    return 1
}

# Configure leann as MCP server in Claude Code
configure_leann_mcp() {
    show_setup_step "running" "Configuring MCP server"

    if ! command -v claude &>/dev/null; then
        show_setup_step "error" "Claude Code not found"
        return 1
    fi

    # Add leann-server to Claude MCP config
    if claude mcp add --scope user leann-server -- leann_mcp &>/dev/null; then
        show_setup_step "done" "MCP server configured"
        return 0
    else
        show_setup_step "error" "Failed to configure MCP server"
        return 1
    fi
}

# Main installation function (with live spinner)
install_leann_mcp() {
    local install_needed=false
    local config_needed=false

    # Check what needs to be done
    if ! is_leann_installed; then
        install_needed=true
    fi

    if ! is_leann_mcp_configured; then
        config_needed=true
    fi

    # Nothing to do
    if ! $install_needed && ! $config_needed; then
        return 0
    fi

    # Use spinner for interactive terminals
    if [[ -t 1 ]]; then
        # Install if needed
        if $install_needed; then
            start_spinner "Installing leann for semantic code search"

            local install_result=0
            # Try uv first
            if command -v uv &>/dev/null; then
                update_spinner "Installing leann via uv"
                if ! uv tool install leann-core --with leann &>/dev/null; then
                    install_result=1
                fi
            # Try pipx
            elif command -v pipx &>/dev/null; then
                update_spinner "Installing leann via pipx"
                if ! pipx install leann-core &>/dev/null; then
                    install_result=1
                fi
            # Try pip
            elif command -v pip &>/dev/null; then
                update_spinner "Installing leann via pip"
                if ! pip install --user leann-core &>/dev/null; then
                    install_result=1
                fi
            else
                install_result=1
            fi

            if [[ $install_result -ne 0 ]]; then
                stop_spinner "error" "Failed to install leann"
                echo ""
                echo "${GRAY}Install manually: uv tool install leann-core --with leann${NC}"
                return 1
            fi

            stop_spinner "success" "Leann installed"
        fi

        # Configure MCP if needed
        if $config_needed; then
            start_spinner "Configuring MCP server"

            if ! claude mcp add --scope user leann-server -- leann_mcp &>/dev/null; then
                stop_spinner "error" "Failed to configure MCP"
                echo ""
                echo "${GRAY}Configure manually: claude mcp add --scope user leann-server -- leann_mcp${NC}"
                return 1
            fi

            stop_spinner "success" "MCP server configured"
        fi

        show_setup_complete
    else
        # Non-interactive mode - simple output
        show_setup_progress "Setting up semantic code search (leann)"
        echo ""

        if $install_needed; then
            if ! install_leann; then
                echo "${RED}Error: Failed to install leann.${NC}"
                return 1
            fi
        else
            show_setup_step "done" "Leann already installed"
        fi

        if $config_needed; then
            if ! configure_leann_mcp; then
                echo "${RED}Error: Failed to configure MCP server.${NC}"
                return 1
            fi
        else
            show_setup_step "done" "MCP already configured"
        fi

        show_setup_complete
    fi

    return 0
}

# ============================================================================
# Main Entry Point (for claw startup)
# ============================================================================

# Ensure leann is set up (called from claw ensure_setup)
ensure_leann_setup() {
    # Skip if already set up
    if is_leann_setup_complete; then
        return 0
    fi

    # Try to install and configure
    if install_leann_mcp; then
        mark_leann_setup_complete
        return 0
    else
        # Installation failed - user needs to fix manually
        echo ""
        echo "${YELLOW}Warning: Leann setup incomplete.${NC}"
        echo "${GRAY}Claw will work but without semantic code search.${NC}"
        echo "${GRAY}Run 'claw --setup-leann' to retry.${NC}"
        echo ""
        return 1
    fi
}

# Force reinstall (for --setup-leann flag)
reinstall_leann_mcp() {
    # Remove marker to force reinstall
    rm -f "$CLAW_HOME/.leann-mcp-configured"

    # Remove existing MCP config if present
    if is_leann_mcp_configured; then
        claude mcp remove leann-server &>/dev/null || true
    fi

    # Run setup
    ensure_leann_setup
}
