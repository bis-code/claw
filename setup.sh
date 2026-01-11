#!/bin/bash
# setup.sh - One-time setup script for claw development
# Run this after cloning the repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAW_BIN="$SCRIPT_DIR/bin/claw"
SYMLINK_PATH="/usr/local/bin/claw"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo ""
echo -e "${CYAN}╭─────────────────────────────────────────╮${NC}"
echo -e "${CYAN}│  ${BOLD}claw Setup${NC}${CYAN} - Local Development      │${NC}"
echo -e "${CYAN}╰─────────────────────────────────────────╯${NC}"
echo ""

# Step 1: Create symlink
echo -e "${CYAN}[1/3]${NC} Creating symlink to /usr/local/bin/claw..."
if [[ -L "$SYMLINK_PATH" ]]; then
    existing_target=$(readlink "$SYMLINK_PATH")
    if [[ "$existing_target" == "$CLAW_BIN" ]]; then
        echo -e "  ${GREEN}✓${NC} Symlink already exists and points to this repo"
    else
        echo -e "  ${YELLOW}!${NC} Symlink exists but points to: $existing_target"
        echo -e "  ${CYAN}→${NC} Updating symlink to point to this repo..."
        sudo ln -sf "$CLAW_BIN" "$SYMLINK_PATH"
        echo -e "  ${GREEN}✓${NC} Symlink updated"
    fi
elif [[ -e "$SYMLINK_PATH" ]]; then
    echo -e "  ${YELLOW}!${NC} /usr/local/bin/claw exists but is not a symlink"
    echo -e "  ${YELLOW}!${NC} Please remove it manually and re-run setup.sh"
    exit 1
else
    echo -e "  ${CYAN}→${NC} Creating symlink (requires sudo)..."
    sudo ln -sf "$CLAW_BIN" "$SYMLINK_PATH"
    echo -e "  ${GREEN}✓${NC} Symlink created"
fi

# Step 2: Install git post-merge hook
echo ""
echo -e "${CYAN}[2/3]${NC} Installing git post-merge hook..."
HOOK_SOURCE="$SCRIPT_DIR/hooks/post-merge"
HOOK_DEST="$SCRIPT_DIR/.git/hooks/post-merge"

if [[ -f "$HOOK_DEST" ]]; then
    echo -e "  ${GREEN}✓${NC} Git hook already installed"
else
    cp "$HOOK_SOURCE" "$HOOK_DEST"
    chmod +x "$HOOK_DEST"
    echo -e "  ${GREEN}✓${NC} Git hook installed"
fi

# Step 3: Run initial configuration sync
echo ""
echo -e "${CYAN}[3/3]${NC} Syncing Claude Code configuration..."
"$CLAW_BIN" --update

echo ""
echo -e "${GREEN}╭─────────────────────────────────────────╮${NC}"
echo -e "${GREEN}│  ${BOLD}✓ Setup Complete!${NC}${GREEN}                     │${NC}"
echo -e "${GREEN}╰─────────────────────────────────────────╯${NC}"
echo ""
echo -e "You can now use:"
echo -e "  ${BOLD}claw${NC}              # Start Claude Code"
echo -e "  ${BOLD}claw --version${NC}    # Check version"
echo -e "  ${BOLD}claw --update${NC}     # Sync configuration"
echo ""
echo -e "📦 ${BOLD}Auto-sync enabled:${NC}"
echo -e "   Every time you ${BOLD}git pull${NC}, configuration will auto-sync!"
echo ""
