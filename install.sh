#!/usr/bin/env bash
#
# install.sh - Manual installation script
#

set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="${PREFIX}/bin"
LIB_DIR="${PREFIX}/lib/claude-setup"

echo "Installing claude-setup..."

# Create directories
sudo mkdir -p "$BIN_DIR"
sudo mkdir -p "$LIB_DIR"

# Copy files
sudo cp -r lib/* "$LIB_DIR/"
sudo cp -r templates "$LIB_DIR/"
sudo cp bin/claude-setup "$BIN_DIR/"

# Make executable
sudo chmod +x "$BIN_DIR/claude-setup"

# Update LIB_DIR path in script
sudo sed -i '' "s|LIB_DIR=\"\${SCRIPT_DIR}/../lib\"|LIB_DIR=\"${LIB_DIR}\"|" "$BIN_DIR/claude-setup"

echo "Installed to $BIN_DIR/claude-setup"
echo ""
echo "Run 'claude-setup --help' to get started."
