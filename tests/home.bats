#!/usr/bin/env bats
# Tests for claw home directory management (~/.claw)

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    export CLAW_HOME="$TMP_DIR/claw-home"
    source "$PROJECT_ROOT/lib/home.sh"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Home Initialization
# ============================================================================

@test "home: is_home_initialized returns false when not initialized" {
    run is_home_initialized
    assert_failure
}

@test "home: init_claw_home creates directory structure" {
    run init_claw_home
    assert_success

    assert [ -d "$CLAW_HOME" ]
    assert [ -d "$CLAW_HOME/prompts" ]
    assert [ -d "$CLAW_HOME/rules" ]
    assert [ -d "$CLAW_HOME/skills" ]
    assert [ -d "$CLAW_HOME/cache" ]
    assert [ -d "$CLAW_HOME/logs" ]
}

@test "home: init_claw_home creates config.json" {
    init_claw_home

    assert [ -f "$CLAW_HOME/config.json" ]
    run cat "$CLAW_HOME/config.json"
    assert_output --partial "version"
    assert_output --partial "defaults"
}

@test "home: is_home_initialized returns true after init" {
    init_claw_home

    run is_home_initialized
    assert_success
}

@test "home: init_claw_home skips if already initialized" {
    init_claw_home
    echo "custom" > "$CLAW_HOME/config.json"

    run init_claw_home
    assert_success
    assert_output --partial "already initialized"

    # Config should not be overwritten
    run cat "$CLAW_HOME/config.json"
    assert_output "custom"
}

@test "home: init_claw_home --force reinitializes" {
    init_claw_home
    echo "custom" > "$CLAW_HOME/config.json"

    run init_claw_home --force
    assert_success

    # Config should be overwritten
    run cat "$CLAW_HOME/config.json"
    assert_output --partial "version"
}

# ============================================================================
# Prompt Management
# ============================================================================

@test "home: install_default_prompts creates prompts" {
    init_claw_home
    install_default_prompts

    assert [ -f "$CLAW_HOME/prompts/base.md" ]
    assert [ -f "$CLAW_HOME/prompts/tdd.md" ]
    assert [ -f "$CLAW_HOME/prompts/autonomous.md" ]
}

@test "home: list_prompts shows available prompts" {
    init_claw_home
    install_default_prompts

    run list_prompts
    assert_success
    assert_output --partial "base"
    assert_output --partial "tdd"
}

# ============================================================================
# Rules Management
# ============================================================================

@test "home: install_default_rules copies rule files" {
    init_claw_home
    install_default_rules

    # Should have some rules from templates
    run ls "$CLAW_HOME/rules/"
    assert_success
}

@test "home: list_rules shows available rules" {
    init_claw_home
    echo "# Test Rule" > "$CLAW_HOME/rules/test-rule.md"

    run list_rules
    assert_success
    assert_output --partial "test-rule"
}

# ============================================================================
# Skills Management
# ============================================================================

@test "home: install_default_skills copies skill files" {
    init_claw_home
    install_default_skills

    run ls "$CLAW_HOME/skills/"
    assert_success
}

@test "home: list_skills shows available skills" {
    init_claw_home
    echo "# Test Skill" > "$CLAW_HOME/skills/test-skill.md"

    run list_skills
    assert_success
    assert_output --partial "test-skill"
}

# ============================================================================
# Config Access
# ============================================================================

@test "home: get_config retrieves config values" {
    init_claw_home

    run get_config "version"
    assert_success
    assert_output "0.5.0"
}

@test "home: get_config returns empty for missing keys" {
    init_claw_home

    run get_config "nonexistent"
    assert_output ""
}

# ============================================================================
# Prompt Building
# ============================================================================

@test "home: build_system_prompt includes base prompt" {
    init_claw_home
    install_default_prompts

    run build_system_prompt
    assert_success
    assert_output --partial "CLAUDE.md"  # From base.md
}

@test "home: build_system_prompt includes mode-specific prompt" {
    init_claw_home
    install_default_prompts

    run build_system_prompt --mode tdd
    assert_success
    assert_output --partial "TDD"
}

@test "home: build_system_prompt includes requested rules" {
    init_claw_home
    echo "# Security Rule Content" > "$CLAW_HOME/rules/security.md"

    run build_system_prompt --rules security
    assert_success
    assert_output --partial "Security Rule Content"
}

# ============================================================================
# Full Setup
# ============================================================================

@test "home: setup_claw_home does full setup" {
    run setup_claw_home
    assert_success

    # Check all components
    assert [ -f "$CLAW_HOME/config.json" ]
    assert [ -d "$CLAW_HOME/prompts" ]
    assert [ -d "$CLAW_HOME/rules" ]
    assert [ -d "$CLAW_HOME/skills" ]
}

@test "home: get_claw_home returns home path" {
    run get_claw_home
    assert_success
    assert_output "$CLAW_HOME"
}
