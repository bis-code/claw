#!/usr/bin/env bash
#
# files.sh - File operation functions for claw
# Tracks created/updated/skipped/conflict files during installation
#

# Arrays to track operations
declare -a MANAGED_FILES=()
declare -a CREATED_FILES=()
declare -a UPDATED_FILES=()
declare -a SKIPPED_FILES=()
declare -a CONFLICT_FILES=()

# Reset tracking arrays
reset_tracking() {
    MANAGED_FILES=()
    CREATED_FILES=()
    UPDATED_FILES=()
    SKIPPED_FILES=()
    CONFLICT_FILES=()
}

# Create or update a managed file
# Usage: create_managed_file <target> <filepath> <content> <description> <force> <dry_run>
create_managed_file() {
    local target="$1"
    local filepath="$2"
    local content="$3"
    local description="${4:-}"
    local force="${5:-false}"
    local dry_run="${6:-false}"

    local fullpath="${target}/${filepath}"
    local dir=$(dirname "$fullpath")
    # Calculate checksum with trailing newline to match file format
    local new_checksum=$(printf '%s\n' "$content" | shasum -a 256 | cut -d' ' -f1)

    # Track as managed
    MANAGED_FILES+=("${filepath}:${new_checksum}")

    # Check current state
    if [[ ! -f "$fullpath" ]]; then
        # New file
        if $dry_run; then
            echo -e "  ${GREEN}[NEW]${NC} $filepath ${description:+($description)}"
            CREATED_FILES+=("$filepath")
        else
            mkdir -p "$dir"
            printf '%s\n' "$content" > "$fullpath"
            echo -e "  ${GREEN}✓ Created:${NC} $filepath ${description:+($description)}"
            CREATED_FILES+=("$filepath")
        fi
    elif $force; then
        # Force overwrite
        if $dry_run; then
            echo -e "  ${YELLOW}[FORCE]${NC} $filepath"
            UPDATED_FILES+=("$filepath")
        else
            printf '%s\n' "$content" > "$fullpath"
            echo -e "  ${YELLOW}↻ Forced:${NC} $filepath"
            UPDATED_FILES+=("$filepath")
        fi
    elif is_file_modified "$target" "$filepath"; then
        # User modified - skip unless force
        if $dry_run; then
            echo -e "  ${MAGENTA}[MODIFIED]${NC} $filepath (use --force to overwrite)"
            CONFLICT_FILES+=("$filepath")
        else
            echo -e "  ${MAGENTA}⚠ Skipped:${NC} $filepath (locally modified)"
            SKIPPED_FILES+=("$filepath")
        fi
    else
        # Check if content changed
        local current_checksum=$(calc_checksum "$fullpath")
        if [[ "$current_checksum" != "$new_checksum" ]]; then
            if $dry_run; then
                echo -e "  ${CYAN}[UPDATE]${NC} $filepath"
                UPDATED_FILES+=("$filepath")
            else
                printf '%s\n' "$content" > "$fullpath"
                echo -e "  ${CYAN}↑ Updated:${NC} $filepath"
                UPDATED_FILES+=("$filepath")
            fi
        else
            # No change needed - only show in check mode
            if $dry_run; then
                echo -e "  ${GREEN}[OK]${NC} $filepath"
            fi
        fi
    fi
}

# Print summary of operations
print_summary() {
    local version="$1"
    local check_only="${2:-false}"
    local dry_run="${3:-false}"

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    if $check_only; then
        echo -e "${GREEN}║       Check Complete                                       ║${NC}"
    elif [[ ${#CREATED_FILES[@]} -gt 0 ]] || [[ ${#UPDATED_FILES[@]} -gt 0 ]]; then
        echo -e "${GREEN}║       Setup Complete!                                      ║${NC}"
    else
        echo -e "${GREEN}║       Already Up to Date                                   ║${NC}"
    fi
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ ${#CREATED_FILES[@]} -gt 0 ]]; then
        echo -e "  ${GREEN}Created:${NC}   ${#CREATED_FILES[@]} files"
    fi
    if [[ ${#UPDATED_FILES[@]} -gt 0 ]]; then
        echo -e "  ${CYAN}Updated:${NC}   ${#UPDATED_FILES[@]} files"
    fi
    if [[ ${#SKIPPED_FILES[@]} -gt 0 ]]; then
        echo -e "  ${MAGENTA}Skipped:${NC}   ${#SKIPPED_FILES[@]} files (locally modified)"
    fi
    if [[ ${#CONFLICT_FILES[@]} -gt 0 ]]; then
        echo -e "  ${MAGENTA}Conflicts:${NC} ${#CONFLICT_FILES[@]} files (use --force to overwrite)"
    fi

    echo ""
    echo -e "Version: ${CYAN}v${version}${NC}"
    echo ""

    if ! $check_only && ! $dry_run; then
        if [[ ${#SKIPPED_FILES[@]} -gt 0 ]]; then
            echo -e "${YELLOW}Note:${NC} Some files were skipped because you modified them."
            echo -e "      Use ${CYAN}--force${NC} to overwrite all files."
            echo ""
        fi

        echo -e "Next steps:"
        echo -e "  1. ${YELLOW}Edit CLAUDE.md${NC} to customize for your project"
        echo -e "  2. ${YELLOW}Review .claude/rules/${NC} and modify as needed"
        echo -e "  3. ${YELLOW}Run 'claw check'${NC} to see future updates"
        echo ""
    fi
}
