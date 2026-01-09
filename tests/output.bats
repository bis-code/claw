#!/usr/bin/env bats
# Unit tests for output.sh formatting functions

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup function runs before each test
setup() {
    # Get the project root directory
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export PROJECT_ROOT

    # Source output.sh
    source "$PROJECT_ROOT/lib/output.sh"
}

# ============================================================================
# Color Detection Tests
# ============================================================================

@test "output.sh: colors are set when terminal is interactive" {
    # Colors should be defined (not empty) in test environment
    [[ -n "$RED" ]] || skip "Terminal doesn't support colors"
    [[ -n "$GREEN" ]]
    [[ -n "$YELLOW" ]]
    [[ -n "$BLUE" ]]
}

@test "output.sh: icon constants are defined" {
    [[ "$ICON_SUCCESS" == "✓" ]]
    [[ "$ICON_ERROR" == "✗" ]]
    [[ "$ICON_WARNING" == "⚠" ]]
    [[ "$ICON_INFO" == "ℹ" ]]
}

@test "output.sh: box drawing characters are defined" {
    [[ "$BOX_TL" == "┌" ]]
    [[ "$BOX_H" == "─" ]]
    [[ "$BOX_V" == "│" ]]
}

# ============================================================================
# Print Function Tests
# ============================================================================

@test "print_success: outputs success message with icon" {
    run print_success "Test message"
    assert_success
    assert_output --partial "Test message"
    assert_output --partial "✓"
}

@test "print_error: outputs error message with icon to stderr" {
    run print_error "Error message"
    assert_success
    assert_output --partial "Error message"
    assert_output --partial "✗"
}

@test "print_warning: outputs warning message with icon" {
    run print_warning "Warning message"
    assert_success
    assert_output --partial "Warning message"
    assert_output --partial "⚠"
}

@test "print_info: outputs info message with icon" {
    run print_info "Info message"
    assert_success
    assert_output --partial "Info message"
    assert_output --partial "ℹ"
}

@test "print_step: outputs step message with arrow" {
    run print_step "Step description"
    assert_success
    assert_output --partial "Step description"
    assert_output --partial "→"
}

@test "print_dim: outputs dimmed text" {
    run print_dim "Dimmed text"
    assert_success
    assert_output --partial "Dimmed text"
}

@test "print_bold: outputs bold text" {
    run print_bold "Bold text"
    assert_success
    assert_output --partial "Bold text"
}

# ============================================================================
# Section Header Tests
# ============================================================================

@test "print_header: outputs header with title" {
    run print_header "Test Header"
    assert_success
    assert_output --partial "Test Header"
    assert_output --partial "🦞"
    # Check for box drawing characters
    assert_output --partial "╔"
    assert_output --partial "╗"
}

@test "print_header: accepts custom width" {
    run print_header "Test" 30
    assert_success
    assert_output --partial "Test"
}

@test "print_section: outputs section title" {
    run print_section "Section Title"
    assert_success
    assert_output --partial "Section Title"
    assert_output --partial "┌"
}

@test "print_section_end: outputs section footer" {
    run print_section_end
    assert_success
    assert_output --partial "└"
}

# ============================================================================
# Progress Indicator Tests
# ============================================================================

@test "print_progress: shows 0% for 0 current" {
    run print_progress 0 10
    assert_success
    assert_output --partial "0%"
    assert_output --partial "░"
}

@test "print_progress: shows 50% for half complete" {
    run print_progress 5 10
    assert_success
    assert_output --partial "50%"
    assert_output --partial "█"
    assert_output --partial "░"
}

@test "print_progress: shows 100% for complete" {
    run print_progress 10 10
    assert_success
    assert_output --partial "100%"
    assert_output --partial "█"
}

@test "print_progress: handles zero total" {
    run print_progress 0 0
    assert_success
    assert_output --partial "0%"
}

@test "print_progress: accepts custom width" {
    run print_progress 1 2 10
    assert_success
    assert_output --partial "50%"
}

# ============================================================================
# Table Function Tests
# ============================================================================

@test "print_kv: formats key-value pair" {
    run print_kv "Key" "Value"
    assert_success
    assert_output --partial "Key:"
    assert_output --partial "Value"
}

@test "print_row: outputs table row" {
    run print_row "col1" "col2" "col3"
    assert_success
    assert_output --partial "col1"
    assert_output --partial "col2"
    assert_output --partial "col3"
}

@test "print_table_header: outputs bold header with separator" {
    run print_table_header "Header1" "Header2"
    assert_success
    assert_output --partial "Header1"
    assert_output --partial "Header2"
    # Should include separator line
    assert_output --partial "─"
}

# ============================================================================
# Status Badge Tests
# ============================================================================

@test "print_badge: outputs badge with text" {
    run print_badge "BETA"
    assert_success
    assert_output --partial "[BETA]"
}

@test "print_status: formats success status" {
    run print_status "success"
    assert_success
    assert_output --partial "success"
    assert_output --partial "✓"
}

@test "print_status: formats completed status" {
    run print_status "completed"
    assert_success
    assert_output --partial "completed"
    assert_output --partial "✓"
}

@test "print_status: formats error status" {
    run print_status "error"
    assert_success
    assert_output --partial "error"
    assert_output --partial "✗"
}

@test "print_status: formats failed status" {
    run print_status "failed"
    assert_success
    assert_output --partial "failed"
    assert_output --partial "✗"
}

@test "print_status: formats warning status" {
    run print_status "warning"
    assert_success
    assert_output --partial "warning"
    assert_output --partial "⚠"
}

@test "print_status: formats pending status" {
    run print_status "pending"
    assert_success
    assert_output --partial "pending"
    assert_output --partial "○"
}

@test "print_status: formats running status" {
    run print_status "running"
    assert_success
    assert_output --partial "running"
    assert_output --partial "●"
}

@test "print_status: handles unknown status" {
    run print_status "unknown"
    assert_success
    assert_output "unknown"
}

# ============================================================================
# Utility Function Tests
# ============================================================================

@test "truncate_str: truncates long strings" {
    run truncate_str "This is a very long string that should be truncated" 20
    assert_success
    assert_output "This is a very lo..."
}

@test "truncate_str: keeps short strings unchanged" {
    run truncate_str "Short" 20
    assert_success
    assert_output "Short"
}

@test "truncate_str: uses default max length" {
    local long_str=$(printf '%0.s#' {1..100})
    run truncate_str "$long_str"
    assert_success
    assert_output --partial "..."
}

@test "pad_str: pads string to width" {
    run pad_str "Test" 10
    assert_success
    # Output should be 10 characters
    [[ ${#output} -eq 10 ]]
}

@test "pad_str: uses custom padding char" {
    run pad_str "Test" 10 "-"
    assert_success
    assert_output --partial "Test"
}

@test "center_str: centers string in width" {
    run center_str "Test" 10
    assert_success
    # Should have padding on both sides
    [[ ${#output} -ge 8 ]]
}

# ============================================================================
# Spinner Tests
# ============================================================================

@test "show_spinner: displays spinner frame" {
    run show_spinner
    assert_success
    # Should output a spinner character
    [[ -n "$output" ]]
}

@test "clear_spinner: clears spinner output" {
    run clear_spinner
    assert_success
}

# ============================================================================
# Color Mode Tests (Non-interactive Terminal)
# ============================================================================

@test "output.sh: can be sourced in setup without errors" {
    # If we got here, setup() successfully sourced output.sh
    [[ -n "$PROJECT_ROOT" ]]
    [[ -n "$ICON_SUCCESS" ]]
}
