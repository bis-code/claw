#!/usr/bin/env bash
#
# issue-templates.sh - GitHub issue template management for claw
# Creates and manages .github/ISSUE_TEMPLATE/ files across repos
#

set -euo pipefail

# Template directory (check both dev and installed locations)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "${SCRIPT_DIR}/templates/github-issue-templates" ]]; then
    # Homebrew installed location: lib/claw/templates/
    ISSUE_TEMPLATES_DIR="${SCRIPT_DIR}/templates/github-issue-templates"
else
    # Dev location: lib/../templates/
    ISSUE_TEMPLATES_DIR="${SCRIPT_DIR}/../templates/github-issue-templates"
fi

# Available templates
AVAILABLE_TEMPLATES=(
    "bug-report:Bug Report:Report bugs and unexpected behavior"
    "feature-request:Feature Request:Suggest new features"
    "claude-ready:Claude Ready Task:Tasks ready for Claude Code (/plan-day)"
    "tech-debt:Technical Debt:Track refactoring and tech debt"
)

# ============================================================================
# Template Functions
# ============================================================================

# List available templates
list_available_templates() {
    echo "Available GitHub issue templates:"
    echo ""
    for entry in "${AVAILABLE_TEMPLATES[@]}"; do
        local id="${entry%%:*}"
        local rest="${entry#*:}"
        local name="${rest%%:*}"
        local desc="${rest#*:}"
        echo "  ${id}"
        echo "    ${name} - ${desc}"
        echo ""
    done
}

# Check if gh CLI is available and authenticated
check_gh_auth() {
    if ! command -v gh &>/dev/null; then
        echo "Error: gh CLI not found. Install from https://cli.github.com/" >&2
        return 1
    fi

    if ! gh auth status &>/dev/null 2>&1; then
        echo "Error: gh CLI not authenticated. Run 'gh auth login'" >&2
        return 1
    fi

    return 0
}

# Get template content by ID
get_template_content() {
    local id="$1"
    local template_file="${ISSUE_TEMPLATES_DIR}/${id}.md"

    if [[ ! -f "$template_file" ]]; then
        echo "Error: Template '${id}' not found" >&2
        return 1
    fi

    cat "$template_file"
}

# Install templates to a repo using GitHub API (no clone needed)
install_templates_to_repo() {
    local repo="$1"
    shift
    local templates=("$@")

    if [[ ${#templates[@]} -eq 0 ]]; then
        echo "No templates selected"
        return 0
    fi

    echo "Installing templates to ${repo}..."
    echo ""

    # Get default branch
    local default_branch
    default_branch=$(gh api "repos/${repo}" --jq '.default_branch' 2>/dev/null) || {
        echo "Error: Could not determine default branch for ${repo}" >&2
        return 1
    }

    # Install each template via GitHub API (no clone needed!)
    local installed=0
    for template_id in "${templates[@]}"; do
        local src="${ISSUE_TEMPLATES_DIR}/${template_id}.md"
        local path=".github/ISSUE_TEMPLATE/${template_id}.md"

        if [[ ! -f "$src" ]]; then
            echo "  ✗ ${template_id}.md (template not found locally)"
            continue
        fi

        # Read content and base64 encode
        local content
        content=$(base64 < "$src")

        # Check if file already exists
        local existing_sha=""
        existing_sha=$(gh api "repos/${repo}/contents/${path}" --jq '.sha' 2>/dev/null || echo "")

        # Create or update file via API
        local api_body
        if [[ -n "$existing_sha" ]]; then
            api_body=$(jq -n \
                --arg msg "Update ${template_id} issue template" \
                --arg content "$content" \
                --arg branch "$default_branch" \
                --arg sha "$existing_sha" \
                '{message: $msg, content: $content, branch: $branch, sha: $sha}')
        else
            api_body=$(jq -n \
                --arg msg "Add ${template_id} issue template" \
                --arg content "$content" \
                --arg branch "$default_branch" \
                '{message: $msg, content: $content, branch: $branch}')
        fi

        if gh api "repos/${repo}/contents/${path}" \
            --method PUT \
            --input - <<< "$api_body" &>/dev/null; then
            if [[ -n "$existing_sha" ]]; then
                echo "  ✓ ${template_id}.md (updated)"
            else
                echo "  ✓ ${template_id}.md (created)"
            fi
            installed=$((installed + 1))
        else
            echo "  ✗ ${template_id}.md (API error)"
        fi
    done

    echo ""
    if [[ $installed -gt 0 ]]; then
        echo "✓ Installed ${installed} template(s) to ${repo}"
    else
        echo "No templates were installed"
    fi
}

# Interactive template selection
select_templates_interactive() {
    echo "Select templates to install (space to toggle, enter to confirm):"
    echo ""

    local selected=()
    local i=0

    # Simple selection - list templates and ask for comma-separated IDs
    for entry in "${AVAILABLE_TEMPLATES[@]}"; do
        local id="${entry%%:*}"
        local rest="${entry#*:}"
        local name="${rest%%:*}"
        ((i++))
        echo "  $i) ${id} - ${name}"
    done

    echo ""
    echo "  a) All templates"
    echo "  q) Cancel"
    echo ""
    read -p "Enter choices (e.g., 1,3 or 'a' for all): " choice

    if [[ "$choice" == "q" ]]; then
        return 1
    fi

    if [[ "$choice" == "a" ]]; then
        for entry in "${AVAILABLE_TEMPLATES[@]}"; do
            selected+=("${entry%%:*}")
        done
    else
        IFS=',' read -ra choices <<< "$choice"
        for c in "${choices[@]}"; do
            c=$(echo "$c" | tr -d ' ')
            if [[ "$c" =~ ^[0-9]+$ ]] && [[ $c -ge 1 ]] && [[ $c -le ${#AVAILABLE_TEMPLATES[@]} ]]; then
                local entry="${AVAILABLE_TEMPLATES[$((c-1))]}"
                selected+=("${entry%%:*}")
            fi
        done
    fi

    if [[ ${#selected[@]} -eq 0 ]]; then
        echo "No templates selected"
        return 1
    fi

    echo "${selected[@]}"
}

# Main templates command handler
handle_templates_command() {
    local subcommand="${1:-}"
    shift 2>/dev/null || true

    case "$subcommand" in
        list|ls)
            list_available_templates
            ;;
        install)
            check_gh_auth || return 1

            local repo="${1:-}"
            shift 2>/dev/null || true

            if [[ -z "$repo" ]]; then
                # Try to get current repo
                repo=$(get_current_repo 2>/dev/null || echo "")
                if [[ -z "$repo" ]]; then
                    echo "Usage: claw templates install <owner/repo> [template-ids...]"
                    echo ""
                    echo "Or run from within a git repo with GitHub remote"
                    return 1
                fi
                echo "Using current repo: ${repo}"
                echo ""
            fi

            local templates=("$@")

            if [[ ${#templates[@]} -eq 0 ]]; then
                # Interactive selection
                local selection
                selection=$(select_templates_interactive) || return 1
                read -ra templates <<< "$selection"
            fi

            install_templates_to_repo "$repo" "${templates[@]}"
            ;;
        ""|--help|-h)
            cat << 'EOF'
claw templates - Manage GitHub issue templates

Usage:
  claw templates list                     List available templates
  claw templates install <repo> [ids...]  Install templates to a repo
  claw templates install                  Install to current repo (interactive)

Available templates:
  bug-report      Bug Report template
  feature-request Feature Request template
  claude-ready    Claude Ready task (for /plan-day)
  tech-debt       Technical Debt tracking

Examples:
  claw templates list
  claw templates install myorg/myrepo
  claw templates install myorg/myrepo bug-report claude-ready
  claw templates install  # Current repo, interactive selection

The claude-ready template creates issues that appear in /plan-day.
EOF
            ;;
        *)
            echo "Unknown templates command: $subcommand"
            echo "Run 'claw templates --help' for usage"
            return 1
            ;;
    esac
}
