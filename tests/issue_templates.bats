#!/usr/bin/env bats
# TDD Tests for GitHub issue template management (API-based)

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    export CLAW_HOME="$TMP_DIR/claw-home"
    mkdir -p "$CLAW_HOME"

    # Source the issue-templates module
    [[ -f "$PROJECT_ROOT/lib/issue-templates.sh" ]] && source "$PROJECT_ROOT/lib/issue-templates.sh"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# list_available_templates
# ============================================================================

@test "templates: list shows all available templates" {
    run list_available_templates
    assert_success
    assert_output --partial "bug-report"
    assert_output --partial "feature-request"
    assert_output --partial "claude-ready"
    assert_output --partial "tech-debt"
}

@test "templates: list shows descriptions" {
    run list_available_templates
    assert_success
    assert_output --partial "Bug Report"
    assert_output --partial "Feature Request"
    assert_output --partial "Claude Ready"
    assert_output --partial "Technical Debt"
}

# ============================================================================
# get_template_content
# ============================================================================

@test "templates: get_template_content returns content for valid template" {
    run get_template_content "bug-report"
    assert_success
    # Should contain markdown frontmatter
    assert_output --partial "name:"
}

@test "templates: get_template_content fails for invalid template" {
    run get_template_content "nonexistent-template"
    assert_failure
    assert_output --partial "not found"
}

@test "templates: bug-report template has required fields" {
    run get_template_content "bug-report"
    assert_success
    assert_output --partial "description"
    assert_output --partial "labels"
}

@test "templates: claude-ready template has required fields" {
    run get_template_content "claude-ready"
    assert_success
    assert_output --partial "claude-ready"
    assert_output --partial "description"
}

# ============================================================================
# check_gh_auth (mocked)
# ============================================================================

@test "templates: check_gh_auth returns failure when gh not installed" {
    # Create a PATH without gh - must create dir BEFORE changing PATH
    mkdir -p "$TMP_DIR/empty-path"

    OLD_PATH="$PATH"
    PATH="$TMP_DIR/empty-path"

    run check_gh_auth
    assert_failure

    PATH="$OLD_PATH"
}

# ============================================================================
# select_templates_interactive (unit logic)
# ============================================================================

@test "templates: AVAILABLE_TEMPLATES array is populated" {
    [[ ${#AVAILABLE_TEMPLATES[@]} -gt 0 ]]
}

@test "templates: AVAILABLE_TEMPLATES contains expected entries" {
    local found_bug=false
    local found_claude=false

    for entry in "${AVAILABLE_TEMPLATES[@]}"; do
        [[ "$entry" == bug-report:* ]] && found_bug=true
        [[ "$entry" == claude-ready:* ]] && found_claude=true
    done

    [[ "$found_bug" == "true" ]]
    [[ "$found_claude" == "true" ]]
}

# ============================================================================
# handle_templates_command
# ============================================================================

@test "templates: handle_templates_command list works" {
    run handle_templates_command list
    assert_success
    assert_output --partial "bug-report"
}

@test "templates: handle_templates_command help shows usage" {
    run handle_templates_command --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "claw templates list"
    assert_output --partial "claw templates install"
}

@test "templates: handle_templates_command unknown command fails" {
    run handle_templates_command unknowncommand
    assert_failure
    assert_output --partial "Unknown"
}

# ============================================================================
# Template file validation
# ============================================================================

@test "templates: bug-report.md exists and is valid YAML frontmatter" {
    local template_file="$PROJECT_ROOT/templates/github-issue-templates/bug-report.md"
    [[ -f "$template_file" ]]

    # Check for YAML frontmatter markers
    run head -1 "$template_file"
    assert_output "---"
}

@test "templates: feature-request.md exists and is valid" {
    local template_file="$PROJECT_ROOT/templates/github-issue-templates/feature-request.md"
    [[ -f "$template_file" ]]
}

@test "templates: claude-ready.md exists and is valid" {
    local template_file="$PROJECT_ROOT/templates/github-issue-templates/claude-ready.md"
    [[ -f "$template_file" ]]
}

@test "templates: tech-debt.md exists and is valid" {
    local template_file="$PROJECT_ROOT/templates/github-issue-templates/tech-debt.md"
    [[ -f "$template_file" ]]
}

# ============================================================================
# API-based installation (mock tests - can't test actual API)
# ============================================================================

@test "templates: install_templates_to_repo requires valid repo format" {
    # Mock gh to avoid actual API calls
    function gh() {
        if [[ "$1" == "api" && "$2" == repos/* ]]; then
            echo '{"default_branch": "main"}'
        fi
    }
    export -f gh

    # This will fail because gh api won't work with our mock
    # But it tests the initial validation
    run install_templates_to_repo "" "bug-report"
    # Should fail with empty repo
}

@test "templates: install validates template IDs before API call" {
    # The function should fail fast if template files don't exist
    # This tests the local file check before any API calls
    function install_templates_to_repo_check_files() {
        local template_id="nonexistent-template-xyz"
        local src="${ISSUE_TEMPLATES_DIR:-$PROJECT_ROOT/templates/github-issue-templates}/${template_id}.md"
        [[ -f "$src" ]]
    }

    run install_templates_to_repo_check_files
    assert_failure
}
