#!/usr/bin/env bash
# leann-setup.sh - LEANN MCP server integration for claw

set -euo pipefail

# Check if LEANN is installed
is_leann_installed() {
    command -v leann &>/dev/null
}

# Check if uv is installed
is_uv_installed() {
    command -v uv &>/dev/null
}

# Install LEANN (tries pipx, uv, then pip)
install_leann() {
    echo "Installing LEANN..."

    # Try pipx first (isolated install)
    if command -v pipx &>/dev/null; then
        echo "Using pipx..."
        pipx install leann && echo "LEANN installed successfully. Restart Claude Code to use it." && return 0
    fi

    # Try uv next
    if command -v uv &>/dev/null; then
        echo "Using uv..."
        uv tool install leann && echo "LEANN installed successfully. Restart Claude Code to use it." && return 0
    fi

    # Fall back to pip
    if command -v pip &>/dev/null; then
        echo "Using pip..."
        pip install --user leann && echo "LEANN installed successfully. Restart Claude Code to use it." && return 0
    fi

    echo "Error: No package manager found. Install one of: pipx, uv, or pip"
    return 1
}

# Get default index name for current directory
get_index_name() {
    local dir="${1:-.}"
    local abs_dir
    abs_dir=$(cd "$dir" && pwd)
    # Use directory name as index name, sanitized
    basename "$abs_dir" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]-' '-' | sed 's/-*$//'
}

# Check if index exists
index_exists() {
    local index_name="$1"
    is_leann_installed && leann list 2>/dev/null | grep -q "^${index_name}$"
}

# Setup LEANN as MCP server
setup_leann_mcp() {
    local project_name="${1:-default}"

    if ! is_leann_installed; then
        echo "Error: LEANN is not installed"
        echo "Run: claw leann install"
        return 1
    fi

    echo "Setting up LEANN MCP server for project: $project_name"
    # This would typically involve:
    # 1. Creating a LEANN config
    # 2. Registering with claude CLI
    echo "MCP setup not yet implemented"
}

# Build LEANN index for current project
build_index() {
    local index_name="${1:-$(get_index_name)}"
    local docs_path="${2:-.}"

    if ! is_leann_installed; then
        echo "LEANN is not installed."
        read -p "Install it now? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_leann || return 1
            echo ""
            echo "Run 'claw leann build' again after restarting Claude Code."
            return 0
        else
            echo "Skipped. Install manually with: claw leann install"
            return 1
        fi
    fi

    echo "Building LEANN index: $index_name"
    leann build "$index_name" --docs "$docs_path"
}

# Search LEANN index (auto-creates if missing)
search_index() {
    local query="${1:-}"
    local index_name="${2:-$(get_index_name)}"

    if [[ -z "$query" ]]; then
        echo "Usage: claw leann search <query> [index-name]"
        return 1
    fi

    # Check if LEANN installed
    if ! is_leann_installed; then
        echo "LEANN not installed. Using fallback grep search..."
        fallback_search "$query"
        return 0
    fi

    # Auto-create index if missing
    if ! index_exists "$index_name"; then
        echo "Index '$index_name' not found. Building..."
        leann build "$index_name" --docs . || {
            echo "Index build failed. Using fallback grep search..."
            fallback_search "$query"
            return 0
        }
        echo ""
    fi

    leann search "$index_name" "$query"
}

# Show LEANN status
leann_status() {
    echo "LEANN Status"
    echo "============"
    echo ""

    if is_leann_installed; then
        echo "Installed: Yes"
        echo "Path: $(command -v leann)"
        echo ""
        echo "Indexes:"
        leann list 2>/dev/null | head -20 || echo "  (none)"
    else
        echo "Installed: No"
        echo ""
        echo "To install: claw leann install"
        echo "  (or run 'claw leann build' to auto-install)"
        echo ""
        echo "Package managers available:"
        command -v pipx &>/dev/null && echo "  - pipx (preferred)"
        command -v uv &>/dev/null && echo "  - uv"
        command -v pip &>/dev/null && echo "  - pip"
        ! command -v pipx &>/dev/null && ! command -v uv &>/dev/null && ! command -v pip &>/dev/null && echo "  (none found - install pipx, uv, or pip)"
    fi
}

# Get LEANN agent instructions to inject into CLAUDE.md
get_leann_agent_instructions() {
    cat << 'INSTRUCTIONS'
## Codebase Search with LEANN

This project uses LEANN for semantic codebase search. When you need to find code:

1. **Use the /search command** - This runs LEANN semantic search
2. **Be specific** - Describe what you're looking for semantically
3. **Iterate** - If results aren't helpful, refine your query

Example searches:
- "authentication middleware" - Find auth-related code
- "database connection handling" - Find DB connection code
- "error handling patterns" - Find error handling examples

The search returns the most relevant code snippets with file paths.
INSTRUCTIONS
}

# Inject LEANN instructions into a file
inject_leann_instructions() {
    local target_file="$1"

    if [[ ! -f "$target_file" ]]; then
        echo "Error: Target file does not exist: $target_file"
        return 1
    fi

    local instructions
    instructions=$(get_leann_agent_instructions)

    # Append to the file
    echo "" >> "$target_file"
    echo "$instructions" >> "$target_file"

    echo "LEANN instructions added to $target_file"
}

# Main command router for leann subcommand
leann_cmd() {
    local cmd="${1:-status}"
    shift || true

    case "$cmd" in
        install)
            install_leann
            ;;
        mcp)
            setup_leann_mcp "$@"
            ;;
        index|build)
            build_index "$@"
            ;;
        search)
            search_index "$@"
            ;;
        status)
            leann_status
            ;;
        help)
            echo "LEANN Commands"
            echo "=============="
            echo ""
            echo "  claw leann install  - Install LEANN via uv"
            echo "  claw leann mcp      - Setup LEANN MCP server"
            echo "  claw leann build    - Build search index"
            echo "  claw leann search   - Search the index"
            echo "  claw leann status   - Show LEANN status"
            ;;
        *)
            echo "Unknown LEANN command: $cmd"
            return 1
            ;;
    esac
}

# Fallback search when LEANN is not available
fallback_search() {
    local query="$1"
    local path="${2:-.}"

    # Use ripgrep if available, otherwise grep
    if command -v rg &>/dev/null; then
        rg --color=never -l "$query" "$path" 2>/dev/null || true
    else
        grep -rl "$query" "$path" 2>/dev/null || true
    fi
}
