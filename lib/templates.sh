#!/usr/bin/env bash
#
# templates.sh - Configuration templates and installation logic for claw
# Handles preset-based installation with smart file management
#

# Template directory - check homebrew layout first, then fallback to dev layout
if [[ -d "${LIB_DIR}/templates" ]]; then
    TEMPLATE_DIR="${LIB_DIR}/templates"
else
    TEMPLATE_DIR="${LIB_DIR}/../templates"
fi

# Core rules included in most presets (not slim)
CORE_RULES=(
    "core-constraints.md"
    "git-workflow.md"
    "security.md"
)

# Rules by preset (in addition to core)
declare -A PRESET_RULES
PRESET_RULES[full]="daily-workflow.md lead-reasoning.md operating-modes.md setup-sync.md testing.md efficient-search.md"
PRESET_RULES[base]=""
PRESET_RULES[hardhat]="hardhat.md efficient-search.md"
PRESET_RULES[unity]="unity.md efficient-search.md"
PRESET_RULES[react]="react.md efficient-search.md"
PRESET_RULES[slim]="slim-rules.md"  # Single consolidated file, no core rules

# Install configuration to target directory
install_config() {
    local target="$1"
    local force="${2:-false}"
    local minimal="${3:-false}"
    local dry_run="${4:-false}"
    local preset="${5:-full}"

    reset_tracking

    local installed_version=$(get_installed_version "$target")

    if [[ "$installed_version" != "0.0.0" ]]; then
        echo -e "Installed: ${CYAN}v${installed_version}${NC} → Available: ${GREEN}v${VERSION}${NC}"
        echo ""
    fi

    echo -e "${YELLOW}Processing files...${NC}"
    echo ""

    # Install CLAUDE.md only if it doesn't exist (skip for non-full presets)
    if [[ "$preset" == "full" ]]; then
        if [[ ! -f "${target}/CLAUDE.md" ]]; then
            echo -e "${BLUE}Creating CLAUDE.md...${NC}"
            local claude_md_content=$(cat "${TEMPLATE_DIR}/CLAUDE.md")
            create_managed_file "$target" "CLAUDE.md" "$claude_md_content" "Main instructions" "$force" "$dry_run"
        else
            echo -e "${BLUE}CLAUDE.md exists - skipping (customize as needed)${NC}"
        fi
    fi

    echo ""
    echo -e "${BLUE}Processing managed files...${NC}"

    # Core files (always installed)
    install_template "$target" ".claude/settings.json" "Settings" "$force" "$dry_run"

    # Hooks (only for full preset)
    if [[ "$preset" == "full" ]]; then
        for file in "${TEMPLATE_DIR}/.claude/hooks/"*.sh; do
            if [[ -f "$file" ]]; then
                local name=$(basename "$file")
                install_template "$target" ".claude/hooks/${name}" "Hook" "$force" "$dry_run"
            fi
        done
    fi

    # Core rules (skip for slim preset which uses consolidated rules)
    if [[ "$preset" != "slim" ]]; then
        for rule in "${CORE_RULES[@]}"; do
            if [[ -f "${TEMPLATE_DIR}/.claude/rules/${rule}" ]]; then
                install_template "$target" ".claude/rules/${rule}" "Rule" "$force" "$dry_run"
            fi
        done
    fi

    # Preset-specific rules
    local preset_rules="${PRESET_RULES[$preset]}"
    for rule in $preset_rules; do
        if [[ -f "${TEMPLATE_DIR}/.claude/rules/${rule}" ]]; then
            install_template "$target" ".claude/rules/${rule}" "Rule" "$force" "$dry_run"
        elif [[ -f "${TEMPLATE_DIR}/.claude/presets/${preset}/${rule}" ]]; then
            install_preset_template "$target" "$preset" "$rule" "Rule" "$force" "$dry_run"
        fi
    done

    # Commands and Skills (skip for base/slim presets, skip if --minimal)
    if [[ "$preset" != "base" ]] && [[ "$preset" != "slim" ]] && ! $minimal; then
        # Commands
        for file in "${TEMPLATE_DIR}/.claude/commands/"*.md; do
            if [[ -f "$file" ]]; then
                local name=$(basename "$file")
                install_template "$target" ".claude/commands/${name}" "Command" "$force" "$dry_run"
            fi
        done

        # Skills (use for loop to avoid subshell from pipe)
        for file in $(find "${TEMPLATE_DIR}/.claude/skills" -name "*.md" -type f 2>/dev/null); do
            local relpath="${file#${TEMPLATE_DIR}/}"
            install_template "$target" "$relpath" "Skill" "$force" "$dry_run"
        done

        # Agents
        for file in "${TEMPLATE_DIR}/.claude/agents/"*.md; do
            if [[ -f "$file" ]]; then
                local name=$(basename "$file")
                install_template "$target" ".claude/agents/${name}" "Agent" "$force" "$dry_run"
            fi
        done
    fi

    # Checklists (only for full preset)
    if [[ "$preset" == "full" ]] && ! $minimal; then
        for file in "${TEMPLATE_DIR}/.claude/checklists/"*.md; do
            if [[ -f "$file" ]]; then
                local name=$(basename "$file")
                install_template "$target" ".claude/checklists/${name}" "Checklist" "$force" "$dry_run"
            fi
        done
    fi

    # Create directories
    echo ""
    echo -e "${BLUE}Creating directories...${NC}"
    if ! $dry_run; then
        mkdir -p "${target}/.claude/daily"
        touch "${target}/.claude/daily/.gitkeep"
        echo -e "  ${GREEN}✓${NC} Created: .claude/daily/"
    fi

    # Make hooks executable
    if [[ "$preset" == "full" ]]; then
        echo ""
        echo -e "${BLUE}Making hooks executable...${NC}"
        if ! $dry_run; then
            chmod +x "${target}"/.claude/hooks/*.sh 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Hooks are now executable"
        fi
    fi

    # Write manifest
    if ! $dry_run; then
        write_manifest "$target" "$VERSION" "$preset" "${MANAGED_FILES[@]}"
    fi

    # Print summary
    print_summary "$VERSION" "$dry_run" "$dry_run"
}

# Install a single template file
install_template() {
    local target="$1"
    local filepath="$2"
    local description="$3"
    local force="$4"
    local dry_run="$5"

    local template_path="${TEMPLATE_DIR}/${filepath}"

    if [[ ! -f "$template_path" ]]; then
        return
    fi

    local content=$(cat "$template_path")
    create_managed_file "$target" "$filepath" "$content" "$description" "$force" "$dry_run"
}

# Install a preset-specific template file
install_preset_template() {
    local target="$1"
    local preset="$2"
    local filename="$3"
    local description="$4"
    local force="$5"
    local dry_run="$6"

    local template_path="${TEMPLATE_DIR}/.claude/presets/${preset}/${filename}"

    if [[ ! -f "$template_path" ]]; then
        return
    fi

    local content=$(cat "$template_path")
    create_managed_file "$target" ".claude/rules/${filename}" "$content" "$description" "$force" "$dry_run"
}

# Export configuration from a source repo
export_config() {
    local source="$1"
    local output_dir="${TEMPLATE_DIR}"

    echo -e "${YELLOW}Exporting configuration...${NC}"
    echo ""

    # Create template directories
    mkdir -p "${output_dir}/.claude/"{hooks,rules,commands,checklists}
    mkdir -p "${output_dir}/.claude/skills/daily-workflow"

    # Copy CLAUDE.md template (or create generic)
    if [[ -f "${source}/CLAUDE.md" ]]; then
        echo -e "  ${GREEN}✓${NC} CLAUDE.md"
        cp "${source}/CLAUDE.md" "${output_dir}/CLAUDE.md"
    fi

    # Copy settings.json
    if [[ -f "${source}/.claude/settings.json" ]]; then
        echo -e "  ${GREEN}✓${NC} .claude/settings.json"
        cp "${source}/.claude/settings.json" "${output_dir}/.claude/settings.json"
    fi

    # Copy hooks
    for file in "${source}/.claude/hooks/"*.sh; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file")
            echo -e "  ${GREEN}✓${NC} .claude/hooks/${name}"
            cp "$file" "${output_dir}/.claude/hooks/${name}"
        fi
    done

    # Copy rules
    for file in "${source}/.claude/rules/"*.md; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file")
            echo -e "  ${GREEN}✓${NC} .claude/rules/${name}"
            cp "$file" "${output_dir}/.claude/rules/${name}"
        fi
    done

    # Copy commands
    for file in "${source}/.claude/commands/"*.md; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file")
            echo -e "  ${GREEN}✓${NC} .claude/commands/${name}"
            cp "$file" "${output_dir}/.claude/commands/${name}"
        fi
    done

    # Copy skills
    find "${source}/.claude/skills" -name "*.md" -type f 2>/dev/null | while read file; do
        local relpath="${file#${source}/}"
        local dest_dir=$(dirname "${output_dir}/${relpath}")
        mkdir -p "$dest_dir"
        echo -e "  ${GREEN}✓${NC} ${relpath}"
        cp "$file" "${output_dir}/${relpath}"
    done

    # Copy checklists
    for file in "${source}/.claude/checklists/"*.md; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file")
            echo -e "  ${GREEN}✓${NC} .claude/checklists/${name}"
            cp "$file" "${output_dir}/.claude/checklists/${name}"
        fi
    done

    echo ""
    echo -e "${GREEN}Export complete!${NC}"
    echo -e "Templates saved to: ${CYAN}${output_dir}${NC}"
    echo ""
    echo "To update the installed version, bump the VERSION in bin/claw"
}
