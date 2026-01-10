#!/usr/bin/env bats
# Tests for command consolidation to /auto

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR

    # Copy templates to test directory
    cp -r "$PROJECT_ROOT/templates/.claude" "$TMP_DIR/"
    cp "$PROJECT_ROOT/templates/CLAUDE.md" "$TMP_DIR/"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# New /auto Command Tests
# ============================================================================

@test "consolidation: auto.md skill file exists" {
    [[ -f "$TMP_DIR/.claude/skills/daily-workflow/auto.md" ]]
}

@test "consolidation: auto.md command file exists" {
    [[ -f "$TMP_DIR/.claude/commands/auto.md" ]]
}

@test "consolidation: auto.md has unified description" {
    run grep -q "One command to rule them all" "$TMP_DIR/.claude/skills/daily-workflow/auto.md"
    assert_success
}

@test "consolidation: auto.md documents --plan-only flag" {
    run grep -q "\-\-plan-only" "$TMP_DIR/.claude/skills/daily-workflow/auto.md"
    assert_success
}

@test "consolidation: auto.md documents --skip-discovery flag" {
    run grep -q "\-\-skip-discovery" "$TMP_DIR/.claude/skills/daily-workflow/auto.md"
    assert_success
}

@test "consolidation: auto.md has invocation table" {
    run grep -q "| Command | Discovery | Planning | Execution | Shipping |" "$TMP_DIR/.claude/skills/daily-workflow/auto.md"
    assert_success
}

# ============================================================================
# Deprecation Notice Tests
# ============================================================================

@test "consolidation: auto-pilot.md deprecation file exists" {
    [[ -f "$TMP_DIR/.claude/skills/daily-workflow/auto-pilot.md" ]]
}

@test "consolidation: auto-pilot.md has deprecation warning" {
    run grep -q "DEPRECATED" "$TMP_DIR/.claude/skills/daily-workflow/auto-pilot.md"
    assert_success
}

@test "consolidation: auto-pilot.md redirects to /auto" {
    run grep -q "Redirect to /auto" "$TMP_DIR/.claude/skills/daily-workflow/auto-pilot.md"
    assert_success
}

@test "consolidation: auto-pilot command has deprecation notice" {
    run grep -q "DEPRECATED" "$TMP_DIR/.claude/commands/auto-pilot.md"
    assert_success
}

# ============================================================================
# Alias Tests (/plan-day)
# ============================================================================

@test "consolidation: plan-day.md has alias notice" {
    run grep -qi "alias.*for.*auto.*plan-only" "$TMP_DIR/.claude/skills/daily-workflow/plan-day.md"
    assert_success
}

@test "consolidation: plan-day.md recommends using /auto" {
    run grep -q "Via /auto (Recommended)" "$TMP_DIR/.claude/skills/daily-workflow/plan-day.md"
    assert_success
}

@test "consolidation: plan-day command has alias notice" {
    run grep -q "alias for /auto --plan-only" "$TMP_DIR/.claude/commands/plan-day.md"
    assert_success
}

# ============================================================================
# Internal Command Marking Tests
# ============================================================================

@test "consolidation: autonomous.md marked as internal" {
    run grep -qi "internal.*called by.*auto" "$TMP_DIR/.claude/commands/autonomous.md"
    assert_success
}

@test "consolidation: brainstorm.md marked as internal" {
    run grep -qi "internal.*called by.*auto" "$TMP_DIR/.claude/commands/brainstorm.md"
    assert_success
}

@test "consolidation: autonomous.md recommends using /auto" {
    run grep -qi "use.*auto.*instead" "$TMP_DIR/.claude/commands/autonomous.md"
    assert_success
}

@test "consolidation: brainstorm.md recommends using /auto" {
    run grep -qi "use.*auto" "$TMP_DIR/.claude/commands/brainstorm.md"
    assert_success
}

# ============================================================================
# Documentation Update Tests
# ============================================================================

@test "consolidation: CLAUDE.md documents /auto command" {
    run grep -q "## Autonomous Development: /auto Command" "$TMP_DIR/CLAUDE.md"
    assert_success
}

@test "consolidation: CLAUDE.md has /auto quick start" {
    run grep -q "/auto.*# Full cycle" "$TMP_DIR/CLAUDE.md"
    assert_success
}

@test "consolidation: CLAUDE.md mentions /plan-day alias" {
    run grep -qi "plan-day.*alias.*auto.*plan-only" "$TMP_DIR/CLAUDE.md"
    assert_success
}

@test "consolidation: extended-thinking.md references /auto not /auto-pilot" {
    # Should reference /auto
    run grep -q "/auto.*Unified autonomous development" "$TMP_DIR/.claude/rules/extended-thinking.md"
    assert_success

    # Should NOT reference /auto-pilot
    run grep -q "/auto-pilot.*Autonomous execution planning" "$TMP_DIR/.claude/rules/extended-thinking.md"
    assert_failure
}

# ============================================================================
# Migration Path Tests
# ============================================================================

@test "consolidation: auto-pilot.md has migration guide" {
    run grep -q "Migration" "$TMP_DIR/.claude/skills/daily-workflow/auto-pilot.md"
    assert_success
}

@test "consolidation: auto-pilot.md maps old flags to new flags" {
    run grep -q "discover-only.*plan-only" "$TMP_DIR/.claude/commands/auto-pilot.md"
    assert_success
}

@test "consolidation: auto-pilot.md shows flag comparison table" {
    run grep -q "| Old \`/auto-pilot\` | New \`/auto\` |" "$TMP_DIR/.claude/commands/auto-pilot.md"
    assert_success
}

# ============================================================================
# Flag Documentation Tests
# ============================================================================

@test "consolidation: auto.md documents all flags" {
    local auto_file="$TMP_DIR/.claude/commands/auto.md"

    # Check for each flag
    grep -q "\-\-plan-only" "$auto_file"
    grep -q "\-\-skip-discovery" "$auto_file"
    grep -q "\-\-hours" "$auto_file"
    grep -q "\-\-focus" "$auto_file"
    grep -q "\-\-discovery" "$auto_file"
}

@test "consolidation: auto.md has flag comparison table" {
    # Check in skill file where the detailed table is
    run grep -q "| Command | Discovery | Planning | Execution | Shipping |" "$TMP_DIR/.claude/skills/daily-workflow/auto.md"
    assert_success
}

# ============================================================================
# Integration Tests
# ============================================================================

@test "consolidation: SKILL.md uses /auto not /auto-pilot" {
    run grep "/auto-pilot" "$TMP_DIR/.claude/skills/daily-workflow/SKILL.md"
    assert_failure

    run grep -q "/auto" "$TMP_DIR/.claude/skills/daily-workflow/SKILL.md"
    assert_success
}

@test "consolidation: slim-rules.md references /auto not /auto-pilot" {
    run grep -q "/auto for autonomous work" "$TMP_DIR/.claude/presets/slim/slim-rules.md"
    assert_success

    run grep "/auto-pilot" "$TMP_DIR/.claude/presets/slim/slim-rules.md"
    assert_failure
}

# ============================================================================
# Backward Compatibility Tests
# ============================================================================

@test "consolidation: deprecation files preserve old command names" {
    # Should still mention the old command for reference
    run grep -q "/auto-pilot" "$TMP_DIR/.claude/skills/daily-workflow/auto-pilot.md"
    assert_success
}

@test "consolidation: all deprecation notices point to correct new command" {
    local skill_deprecation="$TMP_DIR/.claude/skills/daily-workflow/auto-pilot.md"
    local command_deprecation="$TMP_DIR/.claude/commands/auto-pilot.md"

    # Both should reference /auto as the replacement (case insensitive)
    grep -qi "use.*auto.*instead" "$skill_deprecation"
    grep -qi "use.*auto.*instead" "$command_deprecation"
}
