#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAW_BIN="$HOME/.local/bin/claw"
CLAUDE_LIB="$HOME/.claude/lib"

# Functions
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

is_dev_mode() {
    [[ -L "$CLAW_BIN" ]] && [[ "$(readlink "$CLAW_BIN")" == "$PROJECT_DIR/bin/claw" ]]
}

show_status() {
    echo ""
    echo "════════════════════════════════════════"
    echo "  Claw Development Mode Status"
    echo "════════════════════════════════════════"
    echo ""
    
    if is_dev_mode; then
        print_success "Development mode is ACTIVE"
        echo ""
        print_info "Your changes are instantly available!"
        echo ""
        echo "  Binary:  $CLAW_BIN"
        echo "           → $(readlink "$CLAW_BIN")"
        echo ""
        if [[ -L "$CLAUDE_LIB" ]]; then
            echo "  Library: $CLAUDE_LIB"
            echo "           → $(readlink "$CLAUDE_LIB")"
        fi
    else
        print_warning "Development mode is INACTIVE"
        echo ""
        print_info "Using installed version (if any)"
        echo ""
        if [[ -f "$CLAW_BIN" ]]; then
            echo "  Binary:  $CLAW_BIN (regular file)"
        else
            echo "  Binary:  Not installed"
        fi
    fi
    echo ""
}

enable_dev_mode() {
    echo ""
    print_info "Enabling development mode..."
    echo ""
    
    # Create directories if needed
    mkdir -p "$(dirname "$CLAW_BIN")"
    mkdir -p "$(dirname "$CLAUDE_LIB")"
    
    # Backup existing if not symlink
    if [[ -f "$CLAW_BIN" ]] && [[ ! -L "$CLAW_BIN" ]]; then
        print_info "Backing up existing binary to ${CLAW_BIN}.backup"
        mv "$CLAW_BIN" "${CLAW_BIN}.backup"
    fi
    
    if [[ -d "$CLAUDE_LIB" ]] && [[ ! -L "$CLAUDE_LIB" ]]; then
        print_info "Backing up existing lib to ${CLAUDE_LIB}.backup"
        mv "$CLAUDE_LIB" "${CLAUDE_LIB}.backup"
    fi
    
    # Create symlinks
    ln -sf "$PROJECT_DIR/bin/claw" "$CLAW_BIN"
    print_success "Linked binary: $CLAW_BIN → $PROJECT_DIR/bin/claw"
    
    ln -sf "$PROJECT_DIR/lib" "$CLAUDE_LIB"
    print_success "Linked library: $CLAUDE_LIB → $PROJECT_DIR/lib"
    
    echo ""
    print_success "Development mode enabled!"
    echo ""
    print_info "Now edit code and test instantly with: claw --version"
    echo ""
}

disable_dev_mode() {
    echo ""
    print_info "Disabling development mode..."
    echo ""
    
    # Remove symlinks
    if [[ -L "$CLAW_BIN" ]]; then
        rm "$CLAW_BIN"
        print_success "Removed symlink: $CLAW_BIN"
    fi
    
    if [[ -L "$CLAUDE_LIB" ]]; then
        rm "$CLAUDE_LIB"
        print_success "Removed symlink: $CLAUDE_LIB"
    fi
    
    # Restore backups if they exist
    if [[ -f "${CLAW_BIN}.backup" ]]; then
        mv "${CLAW_BIN}.backup" "$CLAW_BIN"
        print_success "Restored backup binary"
    fi
    
    if [[ -d "${CLAUDE_LIB}.backup" ]]; then
        mv "${CLAUDE_LIB}.backup" "$CLAUDE_LIB"
        print_success "Restored backup library"
    fi
    
    echo ""
    print_success "Development mode disabled!"
    echo ""
    print_info "To use claw, run: ./install.sh"
    echo ""
}

run_tests() {
    echo ""
    print_info "Running tests..."
    echo ""
    
    if ! command -v bats &>/dev/null; then
        print_error "bats not found. Install it first:"
        echo "    git clone https://github.com/bats-core/bats-core.git tests/bats"
        exit 1
    fi
    
    bats tests/
}

quick_test() {
    echo ""
    print_info "Quick functionality test..."
    echo ""
    
    # Test binary exists
    if ! command -v claw &>/dev/null; then
        print_error "claw not found in PATH"
        echo ""
        echo "Enable dev mode first: ./dev-mode.sh on"
        exit 1
    fi
    
    # Test version
    echo -n "Testing version... "
    if claw --version &>/dev/null; then
        print_success "OK"
    else
        print_error "FAILED"
        exit 1
    fi
    
    # Test help
    echo -n "Testing help... "
    if claw --help | grep -q "Command Line Automated Workflow"; then
        print_success "OK"
    else
        print_error "FAILED"
        exit 1
    fi
    
    # Test binary location
    echo ""
    print_info "Binary location: $(which claw)"
    if is_dev_mode; then
        print_success "Using development version"
    else
        print_warning "Using installed version"
    fi
    
    echo ""
    print_success "All quick tests passed!"
    echo ""
}

show_help() {
    cat <<'HELP'
Usage: ./dev-mode.sh [command]

Commands:
  on       Enable development mode (symlink to working code)
  off      Disable development mode (restore original)
  status   Show current mode status
  test     Run quick functionality tests
  full     Run full test suite
  help     Show this help message

Examples:
  ./dev-mode.sh on              # Start developing with instant feedback
  ./dev-mode.sh status          # Check if dev mode is active
  ./dev-mode.sh test            # Quick test after changes
  ./dev-mode.sh off             # Return to normal installation

Development Workflow:
  1. ./dev-mode.sh on           # Enable dev mode
  2. vim bin/claw               # Make changes
  3. claw --version             # Test instantly!
  4. ./dev-mode.sh test         # Quick validation
  5. ./dev-mode.sh off          # Clean up when done
HELP
}

# Main
case "${1:-status}" in
    on|enable|start)
        enable_dev_mode
        ;;
    off|disable|stop)
        disable_dev_mode
        ;;
    status|check)
        show_status
        ;;
    test|quick)
        quick_test
        ;;
    full|tests)
        run_tests
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
