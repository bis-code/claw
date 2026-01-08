#!/usr/bin/env bash
#
# projects.sh - Project-based multi-repo management for claw
# Allows grouping local repos into projects with shared context
#

set -euo pipefail

CLAW_HOME="${CLAW_HOME:-$HOME/.claw}"
PROJECTS_DIR="$CLAW_HOME/projects"

# ============================================================================
# Git Utilities
# ============================================================================

# Get current repo from git remote (owner/repo format)
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

    echo "$repo"
}

# ============================================================================
# Project Configuration
# ============================================================================

# Initialize projects directory
init_projects_dir() {
    mkdir -p "$PROJECTS_DIR"
}

# Get project config file path
get_project_config() {
    local project_name="$1"
    echo "$PROJECTS_DIR/$project_name/config.json"
}

# Check if project exists
project_exists() {
    local project_name="$1"
    [[ -f "$(get_project_config "$project_name")" ]]
}

# Create a new project
# Usage: project_create <name> [--description "desc"]
project_create() {
    local name="$1"
    local description="${2:-}"

    init_projects_dir

    if project_exists "$name"; then
        echo "Project '$name' already exists"
        return 1
    fi

    local project_dir="$PROJECTS_DIR/$name"
    mkdir -p "$project_dir"

    # Create config
    cat > "$project_dir/config.json" << EOF
{
  "name": "$name",
  "description": "$description",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "repos": []
}
EOF

    echo "Created project: $name"
    echo "Add repos with: claw project add-repo /path/to/repo"
}

# Add a local repo to a project
# Usage: project_add_repo <path> [--project <name>]
project_add_repo() {
    local repo_path=""
    local project_name=""
    local repo_name=""
    local github_repo=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project|-p)
                project_name="$2"
                shift 2
                ;;
            --name|-n)
                repo_name="$2"
                shift 2
                ;;
            *)
                repo_path="$1"
                shift
                ;;
        esac
    done

    # Validate path
    if [[ -z "$repo_path" ]]; then
        echo "Usage: claw project add-repo <path> [--project <name>]"
        return 1
    fi

    # Convert to absolute path
    if [[ ! "$repo_path" = /* ]]; then
        repo_path="$(cd "$repo_path" 2>/dev/null && pwd)"
    fi

    if [[ ! -d "$repo_path" ]]; then
        echo "Error: Directory not found: $repo_path"
        return 1
    fi

    # Check if it's a git repo
    if [[ ! -d "$repo_path/.git" ]]; then
        echo "Error: Not a git repository: $repo_path"
        return 1
    fi

    # Get or detect project name
    if [[ -z "$project_name" ]]; then
        # First try to detect from target repo path
        project_name=$(detect_project_from_path "$repo_path")
        # Then try from current working directory
        if [[ -z "$project_name" ]]; then
            project_name=$(detect_project_from_path "$(pwd)")
        fi
        if [[ -z "$project_name" ]]; then
            echo "Error: No project specified and none detected"
            echo "Either specify --project <name> or run from within a project repo"
            return 1
        fi
    fi

    if ! project_exists "$project_name"; then
        echo "Error: Project '$project_name' does not exist"
        echo "Create it with: claw project create $project_name"
        return 1
    fi

    # Auto-detect repo name from folder
    if [[ -z "$repo_name" ]]; then
        repo_name=$(basename "$repo_path")
    fi

    # Try to get GitHub remote
    github_repo=$(cd "$repo_path" && git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' || echo "")

    local config_file
    config_file=$(get_project_config "$project_name")

    # Check if repo already added
    if jq -e --arg path "$repo_path" '.repos[] | select(.path == $path)' "$config_file" &>/dev/null; then
        echo "Repo already in project: $repo_path"
        return 0
    fi

    # Add repo to project config
    local repo_entry
    repo_entry=$(jq -n \
        --arg name "$repo_name" \
        --arg path "$repo_path" \
        --arg github "$github_repo" \
        '{name: $name, path: $path, github: $github}')

    jq --argjson repo "$repo_entry" '.repos += [$repo]' "$config_file" > "$config_file.tmp" \
        && mv "$config_file.tmp" "$config_file"

    # Create marker file in repo
    mkdir -p "$repo_path/.claw"
    cat > "$repo_path/.claw/project.json" << EOF
{
  "project": "$project_name",
  "name": "$repo_name"
}
EOF

    echo "Added to project '$project_name': $repo_name ($repo_path)"
    [[ -n "$github_repo" ]] && echo "  GitHub: $github_repo"
    return 0
}

# Remove a repo from a project
project_remove_repo() {
    local repo_path="$1"
    local project_name="${2:-}"

    # Convert to absolute path
    if [[ ! "$repo_path" = /* ]]; then
        repo_path="$(cd "$repo_path" 2>/dev/null && pwd)"
    fi

    # Detect project if not specified
    if [[ -z "$project_name" ]]; then
        project_name=$(detect_project_from_path "$repo_path")
    fi

    if [[ -z "$project_name" ]]; then
        echo "Error: Could not determine project"
        return 1
    fi

    local config_file
    config_file=$(get_project_config "$project_name")

    # Remove from config
    jq --arg path "$repo_path" '.repos = [.repos[] | select(.path != $path)]' "$config_file" > "$config_file.tmp" \
        && mv "$config_file.tmp" "$config_file"

    # Remove marker file
    rm -f "$repo_path/.claw/project.json"

    echo "Removed from project: $repo_path"
}

# ============================================================================
# Project Detection
# ============================================================================

# Detect project from current directory or path
detect_project_from_path() {
    local path="${1:-$(pwd)}"

    # Check for .claw/project.json marker
    if [[ -f "$path/.claw/project.json" ]]; then
        jq -r '.project' "$path/.claw/project.json" 2>/dev/null
        return 0
    fi

    # Walk up directory tree looking for marker
    while [[ "$path" != "/" ]]; do
        if [[ -f "$path/.claw/project.json" ]]; then
            jq -r '.project' "$path/.claw/project.json" 2>/dev/null
            return 0
        fi
        path=$(dirname "$path")
    done

    return 0  # Return empty, not error
}

# Get current project name (from cwd)
get_current_project() {
    detect_project_from_path "$(pwd)"
}

# ============================================================================
# Project Queries
# ============================================================================

# List all projects
project_list() {
    init_projects_dir

    local projects
    projects=$(find "$PROJECTS_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sort)

    if [[ -z "$projects" ]]; then
        echo "No projects configured"
        echo ""
        echo "Create one with: claw project create <name>"
        return 0
    fi

    local current_project
    current_project=$(get_current_project)

    echo "Projects:"
    echo ""
    while IFS= read -r proj; do
        local config_file="$PROJECTS_DIR/$proj/config.json"
        local repo_count
        repo_count=$(jq '.repos | length' "$config_file" 2>/dev/null || echo 0)
        local desc
        desc=$(jq -r '.description // ""' "$config_file" 2>/dev/null)

        if [[ "$proj" == "$current_project" ]]; then
            echo "  * $proj ($repo_count repos) ← current"
        else
            echo "    $proj ($repo_count repos)"
        fi
        [[ -n "$desc" ]] && echo "      $desc"
    done <<< "$projects"
    return 0
}

# Show project details
project_show() {
    local project_name="${1:-}"

    if [[ -z "$project_name" ]]; then
        project_name=$(get_current_project)
    fi

    if [[ -z "$project_name" ]]; then
        echo "Not in a project. Specify one: claw project show <name>"
        return 1
    fi

    if ! project_exists "$project_name"; then
        echo "Project not found: $project_name"
        return 1
    fi

    local config_file
    config_file=$(get_project_config "$project_name")

    echo "Project: $project_name"
    echo ""

    local desc
    desc=$(jq -r '.description // ""' "$config_file")
    [[ -n "$desc" ]] && echo "Description: $desc" && echo ""

    echo "Repos:"
    jq -r '.repos[] | "  - \(.name)\n      Path: \(.path)\n      GitHub: \(.github // "not linked")"' "$config_file" 2>/dev/null || echo "  (none)"
}

# Get all repos for current project
get_project_repos() {
    local project_name="${1:-}"

    if [[ -z "$project_name" ]]; then
        project_name=$(get_current_project)
    fi

    if [[ -z "$project_name" ]] || ! project_exists "$project_name"; then
        return 0
    fi

    local config_file
    config_file=$(get_project_config "$project_name")

    jq -r '.repos[].path' "$config_file" 2>/dev/null
}

# Get all GitHub repos for current project (for issue fetching)
get_project_github_repos() {
    local project_name="${1:-}"

    if [[ -z "$project_name" ]]; then
        project_name=$(get_current_project)
    fi

    if [[ -z "$project_name" ]] || ! project_exists "$project_name"; then
        return 0
    fi

    local config_file
    config_file=$(get_project_config "$project_name")

    jq -r '.repos[] | select(.github != null and .github != "") | .github' "$config_file" 2>/dev/null
}

# ============================================================================
# Issue Fetching (Multi-Repo)
# ============================================================================

# Fetch issues from all repos in current project
fetch_project_issues() {
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

    local project_name
    project_name=$(get_current_project)

    local all_issues="[]"

    # Get issues from each GitHub repo in project
    while IFS= read -r github_repo; do
        [[ -z "$github_repo" ]] && continue

        local gh_args=("issue" "list" "--repo" "$github_repo" "--json" "number,title,labels,body,repository" "--state" "$state")
        [[ -n "$label" ]] && gh_args+=("--label" "$label")

        local issues
        issues=$(gh "${gh_args[@]}" 2>/dev/null) || continue

        all_issues=$(echo "$all_issues $issues" | jq -s 'add')
    done < <(get_project_github_repos "$project_name")

    # Also get issues from tracked repos (legacy support)
    if [[ -f "$CLAW_HOME/repos.json" ]]; then
        while IFS= read -r repo; do
            [[ -z "$repo" ]] && continue

            local gh_args=("issue" "list" "--repo" "$repo" "--json" "number,title,labels,body,repository" "--state" "$state")
            [[ -n "$label" ]] && gh_args+=("--label" "$label")

            local issues
            issues=$(gh "${gh_args[@]}" 2>/dev/null) || continue

            all_issues=$(echo "$all_issues $issues" | jq -s 'add')
        done < <(jq -r '.repos[]' "$CLAW_HOME/repos.json" 2>/dev/null)
    fi

    # Deduplicate by number+repo
    echo "$all_issues" | jq 'unique_by(.number, .repository.nameWithOwner)'
}

# ============================================================================
# Workflow Generation
# ============================================================================

# Generate workflow for a repo
# Usage: generate_workflow_for_repo <repo_path> <workflow_type>
generate_workflow_for_repo() {
    local repo_path="$1"
    local workflow_type="${2:-self-improve}"

    if [[ ! -d "$repo_path" ]]; then
        echo "Error: Repo not found: $repo_path"
        return 1
    fi

    if [[ ! -d "$repo_path/.git" ]]; then
        echo "Error: Not a git repo: $repo_path"
        return 1
    fi

    # Create .github/workflows directory
    mkdir -p "$repo_path/.github/workflows"

    local workflow_file="$repo_path/.github/workflows/${workflow_type}.yml"

    # Check if workflow already exists
    if [[ -f "$workflow_file" ]]; then
        echo "  Workflow already exists: $workflow_file"
        return 0
    fi

    # Copy workflow template from claw templates
    local template_file=""

    # Try to find template in Homebrew or source installation
    if [[ -d "${LIB_DIR}/templates/.github/workflows" ]]; then
        template_file="${LIB_DIR}/templates/.github/workflows/${workflow_type}.yml"
    elif [[ -d "${SCRIPT_DIR}/../templates/.github/workflows" ]]; then
        template_file="${SCRIPT_DIR}/../templates/.github/workflows/${workflow_type}.yml"
    fi

    if [[ ! -f "$template_file" ]]; then
        echo "Error: Workflow template not found: ${workflow_type}.yml"
        return 1
    fi

    # Copy template
    cp "$template_file" "$workflow_file"

    echo "  ✓ Generated: $workflow_file"
    return 0
}

# Generate self-improve workflow for all repos in project
# Usage: project_generate_self_improve_workflow [--repo <path>]
project_generate_self_improve_workflow() {
    local workflow_type="self-improve"
    local specific_repo=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo|-r)
                specific_repo="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    local project_name
    project_name=$(get_current_project)

    if [[ -z "$project_name" ]]; then
        echo "Not in a project. Run from a project repo or use 'claw project show'"
        return 1
    fi

    echo "Generating autonomous self-improvement workflow for project: $project_name"
    echo ""

    local generated_count=0
    local skipped_count=0

    if [[ -n "$specific_repo" ]]; then
        # Generate for specific repo
        if generate_workflow_for_repo "$specific_repo" "$workflow_type"; then
            generated_count=$((generated_count + 1))
        else
            skipped_count=$((skipped_count + 1))
        fi
    else
        # Generate for all repos in project
        while IFS= read -r repo_path; do
            [[ -z "$repo_path" ]] && continue

            local repo_name
            repo_name=$(basename "$repo_path")

            echo "Processing: $repo_name"

            if generate_workflow_for_repo "$repo_path" "$workflow_type"; then
                generated_count=$((generated_count + 1))
            else
                skipped_count=$((skipped_count + 1))
            fi
        done < <(get_project_repos "$project_name")
    fi

    echo ""
    echo "Summary:"
    echo "  ✓ Generated: $generated_count self-improvement workflows"
    [[ $skipped_count -gt 0 ]] && echo "  - Skipped: $skipped_count (already exist or errors)"
    echo ""
    echo "What happens next:"
    echo "  - Each repo will run daily self-improvement at 2 AM UTC"
    echo "  - Discovers TODOs, test gaps, shellcheck warnings, best practices"
    echo "  - Researches web for trends and improvements"
    echo "  - Implements fixes autonomously with TDD"
    echo "  - Creates PR automatically when done"
    echo ""
    echo "Setup required:"
    echo "  1. Review generated workflows in each repo"
    echo "  2. Add CLAUDE_API_KEY secret to each GitHub repo:"
    echo "     gh secret set CLAUDE_API_KEY --repo <owner/repo>"
    echo "  3. Commit and push the workflows"
}

# ============================================================================
# Command Handler
# ============================================================================

handle_project_command() {
    local subcommand="${1:-}"
    shift 2>/dev/null || true

    case "$subcommand" in
        create)
            local name="${1:-}"
            local desc=""
            shift 2>/dev/null || true

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --description|-d)
                        desc="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done

            if [[ -z "$name" ]]; then
                echo "Usage: claw project create <name> [--description \"desc\"]"
                return 1
            fi

            project_create "$name" "$desc"
            ;;
        add-repo|add)
            project_add_repo "$@"
            ;;
        remove-repo|remove|rm)
            project_remove_repo "$@"
            ;;
        list|ls)
            project_list
            ;;
        show)
            project_show "$@"
            ;;
        issues)
            local json_output=false
            local label=""

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --json|-j)
                        json_output=true
                        shift
                        ;;
                    --label|-l)
                        label="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done

            local args=()
            [[ -n "$label" ]] && args+=(--label "$label")

            local issues
            issues=$(fetch_project_issues "${args[@]}")

            if [[ "$json_output" == "true" ]]; then
                echo "$issues"
            else
                local count
                count=$(echo "$issues" | jq 'length')

                if [[ "$count" -eq 0 ]]; then
                    echo "No issues found in project"
                    return 0
                fi

                echo "Found $count issues:"
                echo ""
                # Group by repo and show with labels
                echo "$issues" | jq -r 'group_by(.repository.nameWithOwner) | .[] |
                    "## " + (.[0].repository.nameWithOwner // "unknown") + "\n" +
                    (. | map("  #" + (.number|tostring) + " " + .title +
                        (if (.labels | length) > 0 then " [" + ([.labels[].name] | join(", ")) + "]" else "" end)
                    ) | join("\n"))' 2>/dev/null
            fi
            ;;
        generate-workflow|generate-self-improve-workflow)
            project_generate_self_improve_workflow "$@"
            ;;
        ""|--help|-h)
            cat << 'EOF'
claw project - Multi-repo project management

Usage:
  claw project create <name>                      Create a new project
  claw project add-repo <path>                    Add local repo to current/specified project
  claw project remove-repo <path>                 Remove repo from project
  claw project list                               List all projects
  claw project show [name]                        Show project details
  claw project issues [--json]                    Fetch issues from all project repos
  claw project generate-self-improve-workflow     Generate autonomous improvement workflows

Options for add-repo:
  --project, -p <name>    Specify project (auto-detects from cwd)
  --name, -n <name>       Override repo name (default: folder name)

Options for generate-self-improve-workflow:
  --repo, -r <path>       Generate for specific repo only (default: all repos)

Examples:
  # Create a project
  claw project create my-game --description "My Game Project"

  # Add local repos to the project
  cd ~/projects/my-game/backend
  claw project add-repo . --project my-game

  cd ~/projects/my-game/frontend
  claw project add-repo .

  # Generate autonomous self-improvement workflows for all repos
  claw project generate-self-improve-workflow

  # Generate for specific repo only
  claw project generate-self-improve-workflow --repo ~/projects/my-game/backend

  # Fetch issues from all project repos
  cd ~/projects/my-game/backend
  claw project issues --label claude-ready

How it works:
  - Projects group multiple local repos together
  - A marker file (.claw/project.json) is added to each repo
  - When you run claw from any project repo, it auto-detects the project
  - Issues are fetched from ALL GitHub repos in the project
  - Workflows enable daily autonomous improvements across all repos
  - This enables cross-repo planning with /plan-day and /brainstorm

About autonomous self-improvement:
  - Runs daily at 2 AM UTC via GitHub Actions
  - Discovers TODOs, test gaps, shellcheck warnings
  - Researches web for best practices and trends
  - Implements fixes with TDD approach
  - Creates PR automatically with all improvements
  - No human interaction required during execution
  - Requires CLAUDE_API_KEY secret in each GitHub repo
EOF
            ;;
        *)
            echo "Unknown project command: $subcommand"
            echo "Run 'claw project --help' for usage"
            return 1
            ;;
    esac
}
