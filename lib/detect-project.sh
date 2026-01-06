#!/usr/bin/env bash
# detect-project.sh - Project type detection for claw

set -euo pipefail

# ============================================================================
# Project Type Detection
# ============================================================================

# Detect the type of project in a directory
# Returns: saas, game-unity, game-godot, web3, library, cli, api, web, mobile, desktop, data-ml, unknown
detect_project_type() {
    local dir="${1:-.}"

    # Game Engines
    if [[ -d "$dir/Assets" ]] && [[ -d "$dir/ProjectSettings" ]]; then
        echo "game-unity"
        return
    fi

    if [[ -f "$dir/project.godot" ]]; then
        echo "game-godot"
        return
    fi

    # Web3/Blockchain
    if [[ -f "$dir/hardhat.config.js" ]] || [[ -f "$dir/hardhat.config.ts" ]] || [[ -f "$dir/foundry.toml" ]]; then
        echo "web3"
        return
    fi

    # Go Projects
    if [[ -f "$dir/go.mod" ]]; then
        if [[ -d "$dir/cmd" ]]; then
            echo "cli"
        else
            echo "library"
        fi
        return
    fi

    # Rust Projects
    if [[ -f "$dir/Cargo.toml" ]]; then
        if grep -q '\[\[bin\]\]' "$dir/Cargo.toml" 2>/dev/null; then
            echo "cli"
        else
            echo "library"
        fi
        return
    fi

    # Python Projects
    if [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/requirements.txt" ]] || [[ -f "$dir/setup.py" ]]; then
        # Check for ML frameworks
        if grep -qE '(torch|tensorflow|sklearn|pandas|numpy|keras|jax)' "$dir/pyproject.toml" "$dir/requirements.txt" 2>/dev/null; then
            echo "data-ml"
            return
        fi
        if [[ -f "$dir/pyproject.toml" ]] && grep -q 'packages' "$dir/pyproject.toml" 2>/dev/null; then
            echo "library"
            return
        fi
        echo "unknown"
        return
    fi

    # Node.js Projects
    if [[ -f "$dir/package.json" ]]; then
        local pkg
        pkg=$(cat "$dir/package.json" 2>/dev/null || echo "{}")

        # Check for mobile frameworks
        if echo "$pkg" | grep -qE '"(react-native|expo)"'; then
            echo "mobile"
            return
        fi

        # Check for desktop frameworks
        if echo "$pkg" | grep -qE '"(electron|@tauri-apps/api)"'; then
            echo "desktop"
            return
        fi

        # Check for CLI
        if echo "$pkg" | grep -q '"bin"'; then
            echo "cli"
            return
        fi

        # Check for SaaS (Next.js + payments/auth)
        if echo "$pkg" | grep -qE '"next"' && echo "$pkg" | grep -qE '"(stripe|@stripe/stripe-js|next-auth|@auth0/nextjs-auth0|clerk)"'; then
            echo "saas"
            return
        fi

        # Check for API frameworks
        if echo "$pkg" | grep -qE '"(express|fastify|koa|hapi|@nestjs/core)"'; then
            echo "api"
            return
        fi

        # Check for frontend frameworks
        if echo "$pkg" | grep -qE '"(next|nuxt|react|vue|svelte|angular)"'; then
            echo "web"
            return
        fi

        # Check for library (has main but no start script)
        if echo "$pkg" | grep -q '"main"' && ! echo "$pkg" | grep -q '"start"'; then
            echo "library"
            return
        fi
    fi

    echo "unknown"
}

# ============================================================================
# Monorepo Detection
# ============================================================================

# Detect packages in a monorepo
# Returns newline-separated list of package paths
detect_monorepo_packages() {
    local dir="${1:-.}"
    local packages=()

    # pnpm workspace
    if [[ -f "$dir/pnpm-workspace.yaml" ]]; then
        # Parse pnpm-workspace.yaml for package globs
        local globs
        globs=$(grep -E '^\s*-\s+' "$dir/pnpm-workspace.yaml" | sed "s/^[[:space:]]*-[[:space:]]*//" | tr -d "'\"\r")
        for glob in $globs; do
            for pkg_dir in "$dir"/$glob; do
                if [[ -d "$pkg_dir" ]]; then
                    packages+=("$pkg_dir")
                fi
            done
        done
    fi

    # npm/yarn workspaces
    if [[ -f "$dir/package.json" ]]; then
        local workspaces
        workspaces=$(grep -o '"workspaces"[^]]*]' "$dir/package.json" 2>/dev/null | grep -oE '"[^"]+\*[^"]*"' | tr -d '"' || echo "")
        for glob in $workspaces; do
            for pkg_dir in "$dir"/$glob; do
                if [[ -d "$pkg_dir" ]]; then
                    packages+=("$pkg_dir")
                fi
            done
        done
    fi

    # Lerna
    if [[ -f "$dir/lerna.json" ]]; then
        local lerna_pkgs
        lerna_pkgs=$(grep -o '"packages"[^]]*]' "$dir/lerna.json" 2>/dev/null | grep -oE '"[^"]+\*[^"]*"' | tr -d '"' || echo "")
        for glob in $lerna_pkgs; do
            for pkg_dir in "$dir"/$glob; do
                if [[ -d "$pkg_dir" ]]; then
                    packages+=("$pkg_dir")
                fi
            done
        done
    fi

    # Turborepo
    if [[ -f "$dir/turbo.json" ]]; then
        # Turborepo uses npm/yarn workspaces, already covered above
        :
    fi

    # Nx
    if [[ -f "$dir/nx.json" ]]; then
        # Nx typically uses apps/ and libs/
        for subdir in "$dir"/apps/* "$dir"/libs/*; do
            if [[ -d "$subdir" ]]; then
                packages+=("$subdir")
            fi
        done
    fi

    # Cargo workspace
    if [[ -f "$dir/Cargo.toml" ]] && grep -q '\[workspace\]' "$dir/Cargo.toml" 2>/dev/null; then
        local members
        members=$(grep -A 10 '\[workspace\]' "$dir/Cargo.toml" | grep -oE '"[^"]+/\*"' | tr -d '"' || echo "")
        for glob in $members; do
            for pkg_dir in "$dir"/$glob; do
                if [[ -d "$pkg_dir" ]]; then
                    packages+=("$pkg_dir")
                fi
            done
        done
    fi

    # Output packages or just the root if not a monorepo
    if [[ ${#packages[@]} -gt 0 ]]; then
        printf '%s\n' "${packages[@]}"
    else
        echo "$dir"
    fi
}

# Get recommended agents for a project type
get_agents_for_type() {
    local type="$1"

    case "$type" in
        saas)
            echo "senior-dev product cto qa ux security"
            ;;
        game-unity|game-godot)
            echo "tools-programmer gameplay-programmer systems-programmer technical-artist qa cto"
            ;;
        web3)
            echo "senior-dev systems-programmer security auditor product qa"
            ;;
        data-ml)
            echo "senior-dev data-scientist mlops qa"
            ;;
        library)
            echo "senior-dev api-designer docs qa"
            ;;
        api)
            echo "senior-dev cto security qa"
            ;;
        web)
            echo "senior-dev ux product qa"
            ;;
        mobile)
            echo "senior-dev ux mobile-specialist qa"
            ;;
        desktop)
            echo "senior-dev ux desktop-specialist qa"
            ;;
        cli)
            echo "senior-dev ux docs qa"
            ;;
        *)
            echo "senior-dev product cto qa ux"
            ;;
    esac
}

# ============================================================================
# Multi-Repo Support
# ============================================================================

# Detect if this repo is part of a multi-repo project
detect_multi_repo() {
    local root="${1:-.}"

    # Check for explicit multi-repo config
    if [[ -f "$root/.claw/multi-repo.json" ]]; then
        cat "$root/.claw/multi-repo.json"
        return 0
    fi

    # Check for config in parent directory
    if [[ -f "$(dirname "$root")/.claw/multi-repo.json" ]]; then
        cat "$(dirname "$root")/.claw/multi-repo.json"
        return 0
    fi

    # Auto-detect sibling repos
    local parent_dir
    parent_dir=$(dirname "$(realpath "$root" 2>/dev/null || echo "$root")")
    local current_name
    current_name=$(basename "$(realpath "$root" 2>/dev/null || echo "$root")")
    local siblings=()

    # Strategy 1: Find all sibling directories that are git repos
    local git_siblings=()
    for sibling_dir in "$parent_dir"/*/; do
        local sib_name
        sib_name=$(basename "$sibling_dir")

        # Skip current directory
        [[ "$sib_name" == "$current_name" ]] && continue

        # Check if it's a git repo
        if [[ -d "$sibling_dir/.git" ]]; then
            git_siblings+=("$sib_name")
        fi
    done

    # Strategy 2: Detect naming patterns (e.g., myapp-frontend, myapp-backend)
    # Extract common prefix from current repo name
    local common_prefix=""
    if [[ "$current_name" =~ ^(.+)[-_](frontend|backend|api|web|app|mobile|desktop|contracts|server|client|core|shared|common|lib|docs|infra)$ ]]; then
        common_prefix="${BASH_REMATCH[1]}"
    fi

    # If we found a common prefix, look for siblings with same prefix
    local related_siblings=()
    if [[ -n "$common_prefix" ]]; then
        for sibling_dir in "$parent_dir"/*/; do
            local sib_name
            sib_name=$(basename "$sibling_dir")
            [[ "$sib_name" == "$current_name" ]] && continue
            if [[ "$sib_name" == "$common_prefix"* ]] || [[ "$sib_name" == *"$common_prefix"* ]]; then
                related_siblings+=("$sib_name")
            fi
        done
    fi

    # Strategy 3: Fallback - check for common multi-repo folder patterns
    local pattern_siblings=()
    local patterns=("frontend" "backend" "api" "contracts" "web" "mobile" "desktop" "docs" "infra" "shared" "common" "server" "client" "app" "dashboard" "admin")
    for pattern in "${patterns[@]}"; do
        if [[ -d "$parent_dir/$pattern" ]] && [[ "$pattern" != "$current_name" ]]; then
            pattern_siblings+=("$pattern")
        fi
    done

    # Prioritize: related by prefix > git repos > pattern matches
    local final_siblings=()
    if [[ ${#related_siblings[@]} -gt 0 ]]; then
        final_siblings=("${related_siblings[@]}")
    elif [[ ${#git_siblings[@]} -gt 0 ]]; then
        final_siblings=("${git_siblings[@]}")
    elif [[ ${#pattern_siblings[@]} -gt 0 ]]; then
        final_siblings=("${pattern_siblings[@]}")
    fi

    if [[ ${#final_siblings[@]} -gt 0 ]]; then
        echo "{"
        echo '  "detected": true,'
        echo "  \"parent\": \"$parent_dir\","
        echo "  \"current\": \"$current_name\","
        [[ -n "$common_prefix" ]] && echo "  \"prefix\": \"$common_prefix\","
        echo '  "siblings": ['
        local first=true
        for sib in "${final_siblings[@]}"; do
            if ! $first; then echo ","; fi
            first=false
            local sib_type
            sib_type=$(detect_project_type "$parent_dir/$sib")
            local sib_remote=""
            if [[ -d "$parent_dir/$sib/.git" ]]; then
                sib_remote=$(git -C "$parent_dir/$sib" remote get-url origin 2>/dev/null || echo "")
            fi
            echo "    {"
            echo "      \"name\": \"$sib\","
            echo "      \"path\": \"$parent_dir/$sib\","
            echo "      \"type\": \"$sib_type\""
            [[ -n "$sib_remote" ]] && echo "      ,\"remote\": \"$sib_remote\""
            echo -n "    }"
        done
        echo ""
        echo "  ]"
        echo "}"
        return 0
    fi

    echo '{"detected": false}'
    return 0
}

# Fetch issues from all repos in a multi-repo setup
fetch_multi_repo_issues() {
    local root="${1:-.}"
    local label="${2:-claude-ready}"

    local multi_json
    multi_json=$(detect_multi_repo "$root")
    local detected
    detected=$(echo "$multi_json" | grep -o '"detected": *true' || echo "")

    if [[ -z "$detected" ]]; then
        gh issue list --label "$label" --state open --json number,title,body,labels,milestone 2>/dev/null || echo "[]"
        return
    fi

    echo "{"
    echo '  "aggregated": true,'
    echo '  "repos": ['

    local current_name
    current_name=$(basename "$(realpath "$root" 2>/dev/null || echo "$root")")
    local current_issues
    current_issues=$(gh issue list --label "$label" --state open --json number,title,body,labels 2>/dev/null || echo "[]")

    echo "    {"
    echo "      \"repo\": \"$current_name\","
    echo "      \"path\": \"$root\","
    echo "      \"issues\": $current_issues"
    echo "    }"

    echo "  ],"
    echo "  \"dependencies\": $(detect_cross_repo_dependencies "$root")"
    echo "}"
}

# Detect cross-repo dependencies
detect_cross_repo_dependencies() {
    local root="${1:-.}"
    local deps=()

    local parent_dir
    parent_dir=$(dirname "$(realpath "$root" 2>/dev/null || echo "$root")")
    local current_name
    current_name=$(basename "$(realpath "$root" 2>/dev/null || echo "$root")")

    # Check package.json for local dependencies
    if [[ -f "$root/package.json" ]]; then
        # Look for file: or link: dependencies pointing to siblings
        local file_deps
        file_deps=$(grep -oE '"(file|link):\.\./[^"]+' "$root/package.json" 2>/dev/null | sed 's/"//g' || echo "")
        for dep in $file_deps; do
            local dep_path
            dep_path=$(echo "$dep" | sed 's/^(file|link)://')
            local dep_name
            dep_name=$(basename "$dep_path")
            deps+=("{\"from\": \"$current_name\", \"to\": \"$dep_name\", \"type\": \"npm-local\"}")
        done

        # Look for workspace references
        local workspace_deps
        workspace_deps=$(grep -oE '"workspace:\*"' "$root/package.json" 2>/dev/null || echo "")
        # This indicates pnpm workspace deps - would need to parse further
    fi

    # Check for git submodules
    if [[ -f "$root/.gitmodules" ]]; then
        local submodules
        submodules=$(grep 'path = ' "$root/.gitmodules" | sed 's/.*path = //' || echo "")
        for submod in $submodules; do
            deps+=("{\"from\": \"$current_name\", \"to\": \"$submod\", \"type\": \"git-submodule\"}")
        done
    fi

    # Check for imports/references to sibling paths in code
    # Look for common patterns like "../sibling-repo" in imports
    local sibling_imports
    sibling_imports=$(grep -rhoE "from ['\"]\\.\\./(\\w+)" "$root/src" "$root/lib" "$root/app" 2>/dev/null | sort -u | sed "s/from ['\"]\\.\\.\\///" || echo "")
    for imp in $sibling_imports; do
        if [[ -d "$parent_dir/$imp" ]]; then
            deps+=("{\"from\": \"$current_name\", \"to\": \"$imp\", \"type\": \"import\"}")
        fi
    done

    # Output as JSON array
    if [[ ${#deps[@]} -eq 0 ]]; then
        echo "[]"
    else
        echo "["
        local first=true
        for dep in "${deps[@]}"; do
            if ! $first; then echo ","; fi
            first=false
            echo "    $dep"
        done
        echo "  ]"
    fi
}

# Create multi-repo config
create_multi_repo_config() {
    local root="${1:-.}"
    local config_dir="$root/.claw"

    mkdir -p "$config_dir"

    cat > "$config_dir/multi-repo.json" << 'EOF'
{
    "detected": true,
    "repos": [],
    "primary": ""
}
EOF

    echo "Created $config_dir/multi-repo.json"
}

# Print detection summary
print_detection_summary() {
    local dir="${1:-.}"
    local type
    type=$(detect_project_type "$dir")
    local agents
    agents=$(get_agents_for_type "$type")

    echo "Project Type: $type"
    echo "Recommended Agents: $agents"

    local packages
    packages=$(detect_monorepo_packages "$dir")
    local pkg_count
    pkg_count=$(echo "$packages" | wc -l | tr -d ' ')

    if [[ "$pkg_count" -gt 1 ]]; then
        echo "Packages: $pkg_count"
        echo "$packages" | while read -r pkg; do
            local pkg_type
            pkg_type=$(detect_project_type "$pkg")
            echo "  - $(basename "$pkg"): $pkg_type"
        done
    fi
}
