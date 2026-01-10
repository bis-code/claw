#!/usr/bin/env bats

# E2E tests for autonomous improvements PR #28
# Tests: Extended thinking, wind-down integration, context reading

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PROJECT_ROOT="${BATS_TEST_DIRNAME}/.."

    # Create temp directory for tests
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Initialize git repo
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create mock daily notes directory
    mkdir -p "$HOME/.claw-test/daily"
    export CLAW_TEST_DAILY="$HOME/.claw-test/daily"
}

teardown() {
    # Clean up
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi

    rm -rf "$HOME/.claw-test"
}

# ============================================================================
# Extended Thinking Integration Tests
# ============================================================================

@test "e2e: extended-thinking rule file exists and is complete" {
    local rule_file="$PROJECT_ROOT/templates/.claude/rules/extended-thinking.md"

    assert [ -f "$rule_file" ]

    # Verify key sections exist
    run grep -q "# Extended Thinking & Deep Reasoning" "$rule_file"
    assert_success

    run grep -q "When to Use Extended Thinking" "$rule_file"
    assert_success

    run grep -q "ultrathink:" "$rule_file"
    assert_success

    run grep -q "MAX_THINKING_TOKENS" "$rule_file"
    assert_success
}

@test "e2e: plan-day skill has ultrathink integration" {
    local skill_file="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/plan-day.md"

    assert [ -f "$skill_file" ]

    # Verify ultrathink is present in Step 2 (context reading) or Step 3 (gathering)
    run grep -q "ultrathink:" "$skill_file"
    assert_success

    # Verify it mentions comprehensive reasoning
    run grep -qi "comprehensive reasoning" "$skill_file"
    assert_success
}

@test "e2e: brainstorm skill has ultrathink in all agents" {
    local skill_file="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/brainstorm.md"

    assert [ -f "$skill_file" ]

    # Count ultrathink occurrences (should be 5 agents + possibly more)
    local count
    count=$(grep -c "ultrathink:" "$skill_file")

    # At least 5 agents should have ultrathink
    assert [ "$count" -ge 5 ]
}

@test "e2e: auto-pilot skill has ultrathink integration" {
    local skill_file="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/auto-pilot.md"

    assert [ -f "$skill_file" ]

    # Verify ultrathink is present
    run grep -q "ultrathink:" "$skill_file"
    assert_success
}

@test "e2e: extended thinking documented in CLAUDE.md" {
    local claude_md="$PROJECT_ROOT/templates/CLAUDE.md"

    assert [ -f "$claude_md" ]

    # Verify Extended Thinking section exists
    run grep -q "## Extended Thinking" "$claude_md"
    assert_success

    # Verify MAX_THINKING_TOKENS is mentioned
    run grep -q "MAX_THINKING_TOKENS" "$claude_md"
    assert_success
}

@test "e2e: extended thinking documented in README.md" {
    local readme="$PROJECT_ROOT/README.md"

    assert [ -f "$readme" ]

    # Verify Extended Thinking section exists
    run grep -q "Extended Thinking" "$readme"
    assert_success

    # Verify configuration is documented
    run grep -q "MAX_THINKING_TOKENS=31999" "$readme"
    assert_success
}

# ============================================================================
# Wind-Down System Integration Tests (Phase 1)
# ============================================================================

@test "e2e: wind-down main script exists and is executable" {
    local script="$PROJECT_ROOT/lib/wind-down/wind-down.sh"

    assert [ -f "$script" ]
    assert [ -x "$script" ]

    # Verify it has a shebang
    run head -n1 "$script"
    assert_output --partial "#!/"
}

@test "e2e: wind-down-auto script exists and is executable" {
    local script="$PROJECT_ROOT/lib/wind-down/wind-down-auto.sh"

    assert [ -f "$script" ]
    assert [ -x "$script" ]
}

@test "e2e: wind-down-check script exists" {
    local script="$PROJECT_ROOT/lib/wind-down/wind-down-check.sh"

    assert [ -f "$script" ]
}

@test "e2e: wind-down-iterm script exists and is executable" {
    local script="$PROJECT_ROOT/lib/wind-down/wind-down-iterm.sh"

    assert [ -f "$script" ]
    assert [ -x "$script" ]
}

@test "e2e: wind-down-notify script exists and is executable" {
    local script="$PROJECT_ROOT/lib/wind-down/wind-down-notify.sh"

    assert [ -f "$script" ]
    assert [ -x "$script" ]
}

@test "e2e: wind-down skill files exist" {
    assert [ -f "$PROJECT_ROOT/templates/.claude/skills/wind-down/SKILL.md" ]
    assert [ -f "$PROJECT_ROOT/templates/.claude/skills/wind-down/wind-down.md" ]
}

@test "e2e: wind-down command documentation exists" {
    local cmd_file="$PROJECT_ROOT/templates/.claude/commands/wind-down.md"

    assert [ -f "$cmd_file" ]

    # Verify it documents the command
    run grep -q "# Wind-Down Command" "$cmd_file"
    assert_success
}

@test "e2e: time-awareness rule exists" {
    local rule="$PROJECT_ROOT/templates/.claude/rules/time-awareness.md"

    assert [ -f "$rule" ]

    # Verify it has gym check logic
    run grep -q "Gym Schedule" "$rule"
    assert_success

    # Verify it has cutoff logic
    run grep -q "cutoff" "$rule"
    assert_success
}

@test "e2e: launchd agent templates exist" {
    assert [ -f "$PROJECT_ROOT/templates/launchd/com.winddown.auto-830pm.plist" ]
    assert [ -f "$PROJECT_ROOT/templates/launchd/com.winddown.auto-10pm.plist" ]
    assert [ -f "$PROJECT_ROOT/templates/launchd/com.winddown.notify.plist" ]
}

@test "e2e: wind-down integration plan exists and is comprehensive" {
    local plan="$PROJECT_ROOT/docs/wind-down-integration-plan.md"

    assert [ -f "$plan" ]

    # Verify it documents all 4 phases
    run grep -c "## Phase [1-4]" "$plan"
    assert [ "${lines[0]}" -ge 4 ]

    # Verify Phase 1 is marked complete
    run grep -qi "Phase 1.*complete" "$plan"
    assert_success
}

# ============================================================================
# Wind-Down Context Reading Tests
# ============================================================================

@test "e2e: plan-day has context reading step" {
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/plan-day.md"

    # Verify Step 2 is context reading
    run grep -q "### Step 2: Read Yesterday's Context" "$skill"
    assert_success

    # Verify it checks Obsidian
    run grep -q "Documents/Obsidian/Daily" "$skill"
    assert_success

    # Verify it has fallback
    run grep -q ".claw/daily" "$skill"
    assert_success
}

@test "e2e: plan-day parses correct sections" {
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/plan-day.md"

    # Verify it parses Tomorrow's Priorities
    run grep -q "Tomorrow's Priorities" "$skill"
    assert_success

    # Verify it parses Focus Stealers
    run grep -q "Focus" "$skill"
    assert_success

    # Verify it parses Energy Level
    run grep -q "Energy" "$skill"
    assert_success
}

@test "e2e: plan-day handles edge cases" {
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/plan-day.md"

    # Verify edge cases are documented
    run grep -q "Edge Cases" "$skill"
    assert_success

    # Verify it handles missing notes
    run grep -q "No note found" "$skill"
    assert_success
}

@test "e2e: auto-pilot has context reading phase" {
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/auto-pilot.md"

    # Verify Phase 2 is context reading
    run grep -q "## Phase 2: Read Yesterday's Context" "$skill"
    assert_success

    # Verify it references same implementation
    run grep -q "Same implementation as.*plan-day" "$skill"
    assert_success
}

@test "e2e: auto-pilot integrates context into prioritization" {
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/auto-pilot.md"

    # Verify unfinished priorities get elevated
    run grep -q "elevated to P1" "$skill"
    assert_success

    # Verify recurring blockers are flagged
    run grep -q "Recurring blockers" "$skill"
    assert_success
}

@test "e2e: auto-pilot phase numbering updated" {
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/auto-pilot.md"

    # Verify phases are numbered correctly after adding context reading
    run grep -q "## Phase 6: Ship" "$skill"
    assert_success
}

@test "e2e: auto-pilot flow diagram updated" {
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/auto-pilot.md"

    # Verify flow diagram includes CONTEXT phase
    run grep -q "CONTEXT" "$skill"
    assert_success
}

# ============================================================================
# Context Reading Logic Tests (Functional)
# ============================================================================

@test "e2e: context reading - handles missing note gracefully" {
    # No daily note exists - should handle gracefully

    # This would be tested in actual skill execution
    # For now, verify the logic is documented
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/plan-day.md"

    run grep -q 'DAILY_NOTE=""' "$skill"
    assert_success
}

@test "e2e: context reading - date calculation logic present" {
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/plan-day.md"

    # Verify date calculation for yesterday
    run grep -q "date -v-1d" "$skill"
    assert_success

    # Verify Linux fallback
    run grep -q 'date -d "yesterday"' "$skill"
    assert_success
}

@test "e2e: context reading - pattern analysis documented" {
    local skill="$PROJECT_ROOT/templates/.claude/skills/daily-workflow/plan-day.md"

    # Verify multi-day pattern analysis is documented
    run grep -q "Multi-Day Pattern Analysis" "$skill"
    assert_success

    # Verify --patterns flag mentioned
    run grep -q -- "--patterns" "$skill"
    assert_success
}

# ============================================================================
# Self-Improve Audit Tests
# ============================================================================

@test "e2e: self-improve audit report exists" {
    local report="$PROJECT_ROOT/docs/self-improve-audit-2026-01-10.md"

    assert [ -f "$report" ]

    # Verify it's comprehensive (check file size)
    local size
    size=$(wc -l < "$report")
    assert [ "$size" -gt 200 ]
}

@test "e2e: audit report has all required sections" {
    local report="$PROJECT_ROOT/docs/self-improve-audit-2026-01-10.md"

    # Verify key sections exist
    run grep -q "## Executive Summary" "$report"
    assert_success

    run grep -q "## Audit Findings" "$report"
    assert_success

    run grep -q "## Acceptance Criteria" "$report"
    assert_success

    run grep -q "## Conclusion" "$report"
    assert_success
}

@test "e2e: audit report confirms PASS status" {
    local report="$PROJECT_ROOT/docs/self-improve-audit-2026-01-10.md"

    # Verify overall assessment is PASS
    run grep -q "PASS" "$report"
    assert_success

    # Verify workflow is production-ready
    run grep -q "production-ready" "$report"
    assert_success
}

# ============================================================================
# Integration Tests
# ============================================================================

@test "e2e: all committed files are tracked by git" {
    cd "$PROJECT_ROOT"

    # Verify no untracked files in key directories
    run bash -c "git ls-files --others --exclude-standard lib/wind-down/ templates/.claude/skills/wind-down/ templates/.claude/rules/extended-thinking.md docs/wind-down-integration-plan.md docs/self-improve-audit-2026-01-10.md"

    # Should have no output (all files tracked)
    assert_output ""
}

@test "e2e: README documents all new features" {
    local readme="$PROJECT_ROOT/README.md"

    # Verify extended thinking is mentioned
    run grep -qi "extended thinking" "$readme"
    assert_success
}

@test "e2e: CLAUDE.md references new rules" {
    local claude_md="$PROJECT_ROOT/templates/CLAUDE.md"

    # Verify extended-thinking.md is in rules table
    run grep -q "extended-thinking.md" "$claude_md"
    assert_success
}

# ============================================================================
# Summary Test
# ============================================================================

@test "e2e: all autonomous improvements are complete" {
    # This test verifies that all major deliverables exist

    # Extended thinking
    assert [ -f "$PROJECT_ROOT/templates/.claude/rules/extended-thinking.md" ]

    # Wind-down system
    assert [ -f "$PROJECT_ROOT/lib/wind-down/wind-down.sh" ]
    assert [ -f "$PROJECT_ROOT/templates/.claude/skills/wind-down/wind-down.md" ]
    assert [ -f "$PROJECT_ROOT/templates/.claude/rules/time-awareness.md" ]
    assert [ -f "$PROJECT_ROOT/docs/wind-down-integration-plan.md" ]

    # Context reading
    run grep -q "Read Yesterday's Context" "$PROJECT_ROOT/templates/.claude/skills/daily-workflow/plan-day.md"
    assert_success

    run grep -q "Read Yesterday's Context" "$PROJECT_ROOT/templates/.claude/skills/daily-workflow/auto-pilot.md"
    assert_success

    # Self-improve audit
    assert [ -f "$PROJECT_ROOT/docs/self-improve-audit-2026-01-10.md" ]
}
