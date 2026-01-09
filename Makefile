.PHONY: help dev dev-on dev-off dev-status test test-quick test-full install clean

# Default target
help:
	@echo "Claw Development Commands"
	@echo ""
	@echo "Development:"
	@echo "  make dev          - Enable dev mode (instant feedback)"
	@echo "  make dev-on       - Same as 'make dev'"
	@echo "  make dev-off      - Disable dev mode"
	@echo "  make dev-status   - Check dev mode status"
	@echo ""
	@echo "Testing:"
	@echo "  make test         - Quick functionality test"
	@echo "  make test-quick   - Same as 'make test'"
	@echo "  make test-full    - Run full test suite"
	@echo ""
	@echo "Installation:"
	@echo "  make install      - Install claw (production)"
	@echo "  make clean        - Remove all installations"
	@echo ""
	@echo "Quick Start:"
	@echo "  1. make dev       # Enable dev mode"
	@echo "  2. vim bin/claw   # Make changes"
	@echo "  3. claw --version # Test instantly!"
	@echo "  4. make test      # Validate"
	@echo "  5. make dev-off   # Clean up"

# Development mode
dev: dev-on

dev-on:
	@./dev-mode.sh on

dev-off:
	@./dev-mode.sh off

dev-status:
	@./dev-mode.sh status

# Testing
test: test-quick

test-quick:
	@./dev-mode.sh test

test-full:
	@./dev-mode.sh full

# Installation
install:
	@echo "Installing claw..."
	@./install.sh

# Clean up
clean:
	@echo "Cleaning up claw installations..."
	@rm -f ~/.local/bin/claw
	@rm -rf ~/.claude
	@echo "✓ Cleaned"
