#!/usr/bin/env bash
#
# templates.sh - Configuration templates and installation logic
#

# Template directory - check homebrew layout first, then fallback to dev layout
if [[ -d "${LIB_DIR}/templates" ]]; then
    TEMPLATE_DIR="${LIB_DIR}/templates"
else
    TEMPLATE_DIR="${LIB_DIR}/../templates"
fi

# Install configuration to target directory
install_config() {
    local target="$1"
    local force="${2:-false}"
    local minimal="${3:-false}"
    local dry_run="${4:-false}"

    reset_tracking

    local installed_version=$(get_installed_version "$target")

    if [[ "$installed_version" != "0.0.0" ]]; then
        echo -e "Installed: ${CYAN}v${installed_version}${NC} → Available: ${GREEN}v${VERSION}${NC}"
        echo ""
    fi

    echo -e "${YELLOW}Processing files...${NC}"
    echo ""

    # Install CLAUDE.md only if it doesn't exist
    if [[ ! -f "${target}/CLAUDE.md" ]]; then
        echo -e "${BLUE}Creating CLAUDE.md...${NC}"
        local claude_md_content=$(cat "${TEMPLATE_DIR}/CLAUDE.md")
        create_managed_file "$target" "CLAUDE.md" "$claude_md_content" "Main instructions" "$force" "$dry_run"
    else
        echo -e "${BLUE}CLAUDE.md exists - skipping (customize as needed)${NC}"
    fi

    echo ""
    echo -e "${BLUE}Processing managed files...${NC}"

    # Core files (always installed)
    install_template "$target" ".claude/settings.json" "Settings" "$force" "$dry_run"

    # Hooks
    for file in "${TEMPLATE_DIR}/.claude/hooks/"*.sh; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file")
            install_template "$target" ".claude/hooks/${name}" "Hook" "$force" "$dry_run"
        fi
    done

    # Rules (core)
    for file in "${TEMPLATE_DIR}/.claude/rules/"*.md; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file")
            install_template "$target" ".claude/rules/${name}" "Rule" "$force" "$dry_run"
        fi
    done

    # Optional files (skip if --minimal)
    if ! $minimal; then
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

        # Checklists
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
    echo ""
    echo -e "${BLUE}Making hooks executable...${NC}"
    if ! $dry_run; then
        chmod +x "${target}"/.claude/hooks/*.sh 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Hooks are now executable"
    fi

    # Write manifest
    if ! $dry_run; then
        write_manifest "$target" "$VERSION" "${MANAGED_FILES[@]}"
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
    echo "To update the installed version, bump the VERSION in bin/claude-setup"
}
