#!/usr/bin/env bash
#
# manifest.sh - Manifest management functions
#

# Get installed version from manifest
get_installed_version() {
    local target="$1"
    local manifest="${target}/.claude/manifest.json"

    if [[ -f "$manifest" ]]; then
        grep -o '"version": *"[^"]*"' "$manifest" | cut -d'"' -f4
    else
        echo "0.0.0"
    fi
}

# Get file checksum from manifest
get_manifest_checksum() {
    local target="$1"
    local filepath="$2"
    local manifest="${target}/.claude/manifest.json"

    if [[ -f "$manifest" ]]; then
        grep -A1 "\"path\": \"$filepath\"" "$manifest" | grep checksum | cut -d'"' -f4 || echo ""
    else
        echo ""
    fi
}

# Calculate file checksum
calc_checksum() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        shasum -a 256 "$filepath" | cut -d' ' -f1
    else
        echo ""
    fi
}

# Check if file was modified by user
is_file_modified() {
    local target="$1"
    local filepath="$2"
    local fullpath="${target}/${filepath}"

    if [[ ! -f "$fullpath" ]]; then
        return 1  # File doesn't exist, not modified
    fi

    local manifest_checksum=$(get_manifest_checksum "$target" "$filepath")
    if [[ -z "$manifest_checksum" ]]; then
        return 0  # Not in manifest, treat as modified (user-created)
    fi

    local current_checksum=$(calc_checksum "$fullpath")
    [[ "$manifest_checksum" != "$current_checksum" ]]
}

# Write manifest file
write_manifest() {
    local target="$1"
    local version="$2"
    shift 2
    local files=("$@")

    local manifest="${target}/.claude/manifest.json"
    mkdir -p "${target}/.claude"

    cat > "$manifest" << EOF
{
  "version": "$version",
  "generated": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "generator": "claude-setup",
  "files": [
EOF

    local first=true
    for entry in "${files[@]}"; do
        local path=${entry%%:*}
        local checksum=${entry#*:}

        if $first; then
            first=false
        else
            echo "," >> "$manifest"
        fi

        printf '    {"path": "%s", "checksum": "%s"}' "$path" "$checksum" >> "$manifest"
    done

    cat >> "$manifest" << 'EOF'

  ]
}
EOF
}
