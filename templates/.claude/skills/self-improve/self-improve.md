---
name: self-improve
description: Autonomous codebase improvement without human interaction
---

# Self-Improve - Autonomous Code Quality Enhancement

You are an autonomous code improvement agent. Your mission: continuously improve the codebase quality, test coverage, and documentation without requiring human oversight.

## Execution Mode: AUTONOMOUS

**IMPORTANT**: This skill runs WITHOUT human interaction. Do NOT:
- Ask the user questions
- Request approval for changes
- Wait for feedback
- Use AskUserQuestion tool

Instead:
- Make safe, confident decisions
- Use conservative safety thresholds
- Rollback on any uncertainty
- Create PR for review at the end

## Phase 1: Discovery (Budget: 10 minutes)

Run discovery agents in parallel using Task tool:

### Agent 1: TODO Scanner
```bash
grep -rn "TODO\|FIXME\|HACK" \
  --include="*.sh" \
  --include="*.bash" \
  --include="*.md" \
  --exclude-dir=".git" \
  --exclude-dir="node_modules"
```

### Agent 2: Test Coverage Scanner
Find modules without tests:
```bash
# List all lib/*.sh files
# For each, check if tests/**/$(basename file).bats exists
# Report missing test files
```

### Agent 3: Shellcheck Analyzer
```bash
shellcheck -f json **/*.sh 2>/dev/null | jq '.[] | select(.level=="error" or .level=="warning")'
```

### Agent 4: Complexity Scanner
Find functions >50 lines:
```bash
# Parse shell scripts
# Extract function definitions
# Count lines per function
# Report functions >50 lines
```

### Agent 5: Duplication Detector
Find duplicated code blocks (>5 lines identical).

## Phase 2: Prioritization (Budget: 5 minutes)

Score each issue:

**Safety Score** (1-10, higher = safer):
- 10: Add test, fix shellcheck warning, update docs
- 7: Extract function, add error handling
- 5: Refactor logic, change function signature
- 3: Update dependencies, modify API
- 1: Change auth/crypto, breaking changes

**Impact Score** (1-10, higher = more impact):
- 10: Fix critical bug, add test coverage to untested module
- 7: Improve error handling, reduce complexity
- 5: Update documentation, fix shellcheck warning
- 3: Extract helper function, remove duplication
- 1: Fix typo, update comment

**Effort Score** (1-10, lower = less effort):
- 1: Fix typo, update comment
- 3: Add missing test, fix shellcheck warning
- 5: Extract function, add error handling
- 7: Refactor complex logic, update docs
- 10: Major refactor, dependency update

**Final Priority**: `safety * impact / effort`

**Filtering Rules**:
1. Only select issues with safety >= 7
2. Exclude if effort > 7 (too risky for autonomous execution)
3. Sort by priority score descending
4. Select top N that fit in time budget

## Phase 3: Execution (Budget: Remaining time)

For each selected improvement:

### Step 1: Create Checkpoint
```bash
git stash --include-untracked
git tag checkpoint-$(date +%s)
```

### Step 2: Implement Fix

Use TDD approach:
1. Write failing test (if adding functionality)
2. Implement fix
3. Verify test passes

### Step 3: Validate
```bash
# Run affected tests
./tests/bats/bin/bats tests/$(basename $modified_file .sh).bats

# Run integration tests
./test/homebrew-integration.sh --local

# Run shellcheck
shellcheck $modified_file
```

### Step 4: Commit or Rollback
```bash
if tests_passed; then
  git add .
  git commit -m "improve: $(description)

  - $(what changed)
  - $(why it's better)
  - Tests: $(test results)

  Auto-improved by Claude Code /self-improve skill

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
else
  git reset --hard HEAD
  git tag -d checkpoint-$(date +%s)
  echo "Rollback: tests failed"
fi
```

### Step 5: Time Check
If time remaining < 15 minutes, stop execution and proceed to ship phase.

## Phase 4: Ship (Budget: 5 minutes)

Create PR with all improvements:

```bash
# Create branch
git checkout -b auto-improve/$(date +%Y%m%d-%H%M)

# Push
git push origin auto-improve/$(date +%Y%m%d-%H%M)

# Create PR
gh pr create \
  --title "🤖 Automated improvements - $(date +%Y-%m-%d)" \
  --body "$(cat <<EOF
## Summary

Autonomous improvements completed by Claude Code /self-improve skill.

### Changes Made
$(git log main..HEAD --oneline)

### Discovery Report
$(cat discovery-report.md)

### Test Results
All tests passing ✓

### Review Notes
- All changes are non-breaking
- Safety score >= 7 for all changes
- Test coverage improved by X%
- Shellcheck warnings reduced by Y

🤖 Generated with Claude Code /self-improve
EOF
)" \
  --label "automated" \
  --label "quality"
```

## Safety Guardrails

### Hard Limits
- Max 2 hours execution time
- Max 20 commits per run
- Max 5 files modified per commit
- Require all tests to pass before commit

### Excluded Patterns
Never modify:
- `**/secrets/**`
- `**/credentials/**`
- `**/.env*`
- `**/auth/**` (unless adding tests)
- `**/crypto/**` (unless adding tests)

### Rollback Triggers
Rollback immediately if:
- Any test fails
- Shellcheck errors introduced
- Integration tests fail
- Build fails
- File not found errors

### Conservative Mode
If uncertain:
1. Skip the change
2. Log to `improvements-skipped.md`
3. Include in PR for human review

## Success Metrics

Track in commit message:
- Number of improvements made
- Test coverage delta
- Shellcheck warnings delta
- Lines of code delta
- Functions >50 lines delta

## Example Execution

```
✶ Starting autonomous self-improvement

Phase 1: Discovery
  ✓ Found 12 TODOs
  ✓ Found 4 modules without tests
  ✓ Found 8 shellcheck warnings
  ✓ Found 6 functions >50 lines

Phase 2: Prioritization
  → Selected 8 improvements (safety>=7, effort<=5)
  → Estimated time: 1.5 hours

Phase 3: Execution
  1/8 ✓ Add tests for orchestrator.sh [15 min]
  2/8 ✓ Fix shellcheck warnings in projects.sh [5 min]
  3/8 ✓ Extract function from get_agent_prompt [12 min]
  4/8 ✓ Add error handling to cd commands [8 min]
  5/8 ✗ Refactor auto_loop (rollback - tests failed) [10 min]
  6/8 ✓ Add input validation to templates.sh [7 min]
  7/8 ✓ Update documentation for new features [6 min]

  Time budget exhausted (1h 3min remaining)

Phase 4: Ship
  ✓ Created PR #123
  ✓ All tests passing
  ✓ Ready for review

Summary:
- 6 improvements committed
- 1 rollback (failed tests)
- 2 skipped (time budget)
- Test coverage: 65% → 72% (+7%)
- Shellcheck warnings: 8 → 2 (-75%)
```

## Integration with CI/CD

This skill is designed to run in GitHub Actions:

```yaml
# .github/workflows/self-improve.yml
name: Daily Self-Improvement

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
  workflow_dispatch:      # Manual trigger

jobs:
  self-improve:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install claw
        run: brew install bis-code/tap/claw
      - name: Run self-improvement
        run: claw /self-improve --hours 2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Error Handling

If skill encounters fatal errors:
1. Log error to `self-improve-errors.log`
2. Create issue with error details
3. Tag with `self-improve-failure`
4. Exit gracefully (don't leave broken state)

## Output Format

Create `self-improve-report.md`:

```markdown
# Self-Improvement Report - 2024-01-09

## Summary
- Duration: 1h 45m
- Improvements: 6 committed, 1 rollback, 2 skipped
- Test coverage: +7%
- Shellcheck warnings: -75%

## Changes Made

### 1. Add tests for orchestrator.sh
- Added 15 test cases
- Coverage: 0% → 65%
- Commit: abc123f

### 2. Fix shellcheck warnings in projects.sh
- Fixed SC2086: Quote to prevent word splitting
- Fixed SC2155: Declare and assign separately
- Commit: def456a

[... more changes ...]

## Skipped Improvements

### 1. Refactor auto_loop function
- Reason: Tests failed after change
- Action: Rolled back
- Follow-up: Create issue for manual review

### 2. Update all dependencies
- Reason: Time budget exhausted
- Action: Deferred to next run

## Next Run Priorities

1. Complete dependency updates
2. Add tests for wrapper.sh
3. Extract functions from handle_templates_command
```

## Completion Signal

End with:
```
✓ Self-improvement complete
✓ PR created: #123
✓ Ready for review

Run completed in 1h 45m
6 improvements • 1 rollback • 2 skipped
```

**NO** human interaction required. Full autonomy achieved.
