.PHONY: help dev test test-full install clean

# Default target
help:
	@echo "Claw Development Commands"
	@echo ""
	@echo "  make dev        - Enable dev mode (instant feedback)"
	@echo "  make test       - Quick functionality test"
	@echo "  make test-full  - Run full test suite"
	@echo "  make install    - Install claw (disables dev mode)"
	@echo "  make clean      - Remove all installations"
	@echo ""
	@echo "Quick Start:"
	@echo "  make dev       # Enable dev mode"
	@echo "  vim bin/claw   # Make changes"
	@echo "  claw --version # Test instantly!"
	@echo "  make test      # Validate"

# Development mode (idempotent)
dev:
	@./dev-mode.sh on

# Testing
test:
	@./dev-mode.sh test

test-full:
	@./dev-mode.sh full

# Installation (disables dev mode)
install:
	@./dev-mode.sh off 2>/dev/null || true
	@echo "Installing claw..."
	@./install.sh

# Clean up
clean:
	@./dev-mode.sh off 2>/dev/null || true
	@echo "Cleaning up claw installations..."
	@rm -f ~/.local/bin/claw ~/.local/bin/claw.backup
	@rm -rf ~/.claude ~/.claude.backup
	@echo "✓ Cleaned"
