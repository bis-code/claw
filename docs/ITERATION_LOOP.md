# Iteration Loop: Test-Until-Green Approach

## Overview

Inspired by the [Ralph Wiggum plugin](https://medium.com/@njengah/ralph-wiggum-claude-code-new-way-to-run-autonomously-for-hours-without-drama-c5f7e2e8f9e4), claw's `/auto` command now includes **iteration-until-green** logic that prevents settling for "good enough."

**Core principle:** Don't commit code until tests actually pass. Iterate automatically until success or stuck.

## The Problem It Solves

**Before:**
```
For each issue:
  - Implement
  - Run tests once
  - Commit (even if tests failed!)
  - Move to next
```

Result: Broken commits, manual cleanup, wasted time.

**After:**
```
For each issue:
  - LOOP until tests pass or stuck:
      - Implement/fix
      - Run tests
      - Analyze failures
      - Detect if stuck
  - Only commit if tests GREEN
  - Move to next
```

Result: Every commit has passing tests. No broken code.

## How It Works

### Iteration Loop

Each issue gets up to 5 attempts (configurable) to pass all tests:

```
iteration = 0
max_iterations = 5  # Default, configurable

WHILE iteration < max_iterations:
    iteration++

    # Implement or fix based on previous feedback
    work_on_issue()

    # Run full test suite
    test_result = run_tests()

    # SUCCESS: All tests pass
    IF test_result.all_pass:
        commit_and_mark_done()
        BREAK

    # STUCK: Same error 3 times
    IF same_error_count >= 3:
        mark_blocked(blocker: current_error)
        BREAK

    # STUCK: No file changes for 2 iterations
    IF no_progress_detected():
        mark_blocked(blocker: "No progress")
        BREAK

    # Continue iterating
    log_failure(iteration, error)
```

### Stuck Detection

To prevent infinite loops and runaway costs:

| Condition | Threshold | Action |
|-----------|-----------|--------|
| **Same error repeated** | 3 times | Mark STUCK, log blocker, move on |
| **No file changes** | 2 iterations | Mark STUCK, log "no progress", move on |
| **Max iterations** | 5 (default) | Mark BLOCKED, log attempts, move on |

**Philosophy:** Better to identify blockers quickly than waste tokens on impossible issues.

## Usage

### Basic Usage

```bash
# Uses default: 5 iterations per issue
/auto

# Custom max iterations
/auto --max-iterations-per-issue 10   # For complex issues
/auto --max-iterations-per-issue 3    # For simple codebases
```

### When to Adjust Max Iterations

**Increase (10-15 iterations):**
- Complex refactors with many moving parts
- New codebase with unfamiliar patterns
- Issues involving external dependencies

**Decrease (3 iterations):**
- Well-tested, familiar codebase
- Token budget constraints
- Quick daily maintenance

**Default (5 iterations):**
- Most use cases
- Good balance of persistence vs cost control

## What Gets Tracked

### In Daily File

```markdown
### Active
- [ ] #53 - Settings display
  - Iteration: 2/5
  - Last error: TypeError: Cannot read property 'theme' of undefined

### Completed
- [x] #52 - Provider error
  - Iterations: 1/5 (first-try success!)

- [x] #53 - Settings display
  - Iterations: 3/5
  - Iteration log:
    1. Initial implementation → Tests failed (missing validation)
    2. Added validation → Tests failed (edge case)
    3. Fixed edge case → ✅ All tests passing

### Blocked
- [ ] #58 - API encryption
  - Status: STUCK (5/5 iterations)
  - Blocker: External API endpoint returning 404
  - Needs human: Verify API configuration
```

### In Daily Report

```markdown
## Execution Statistics
- Total iterations: 12 (avg 3.0 per completed issue)
- First-try successes: 1 (25%)
- Required retries: 3 (75%)
- Stuck/blocked: 1

## Insights
- Most issues resolved in 2-4 attempts
- Stuck issue: #58 blocked by external dependency
- Value of iteration: 75% of issues needed refinement
```

## Real-World Examples

### Example 1: First-Try Success (Rare but Good)

```markdown
#### Issue #52: Test coverage for billing_handler ✅
- Iterations: 1/5
- Exit reason: All tests passing (first try!)
- Iteration breakdown:
  1. Implemented tests → ✅ All tests passing
```

**Tokens saved:** No wasted iterations on already-good code.

### Example 2: Typical Iteration (Most Common)

```markdown
#### Issue #51: Add retry logic to pipeline ✅
- Iterations: 2/5
- Exit reason: All tests passing
- Iteration breakdown:
  1. Initial implementation → Tests failed (missing error handling)
  2. Added error handling → ✅ All tests passing
```

**Value:** Caught missing error handling before commit.

### Example 3: Complex Issue (Needs Persistence)

```markdown
#### Issue #53: Fix auth token vulnerability ✅
- Iterations: 4/5
- Exit reason: All tests passing
- Iteration breakdown:
  1. Initial fix → Tests failed (missing validation)
  2. Added validation → Tests failed (edge case with expired tokens)
  3. Fixed expiry handling → Tests failed (race condition)
  4. Added locking → ✅ All tests passing
```

**Value:** Discovered race condition through iteration. Would have missed it in single-pass.

### Example 4: Stuck on External Dependency

```markdown
#### Issue #54: Tech debt in stripe.go 🚫 BLOCKED
- Iterations: 5/5
- Exit reason: Max iterations reached
- Blocker: External Stripe API returning 404
- Needs human: Verify Stripe webhook configuration
- Iteration breakdown:
  1. Refactored client → Tests failed (404 on webhook)
  2. Updated endpoint → Tests failed (same 404)
  3. Added debug logging → Tests failed (404 persists)
  4. Checked config → Tests failed (404 persists - STUCK)
  5. Max iterations → Gave up
```

**Value:** Identified blocker (Stripe config) without wasting more tokens. Human can fix root cause.

## Comparison to Ralph Wiggum

| Feature | Ralph Wiggum | claw Iteration Loop |
|---------|--------------|---------------------|
| **Scope** | Single task | Multi-issue queue |
| **Integration** | Standalone plugin | Built into `/auto` |
| **Completion signal** | `<promise>DONE</promise>` | Test results (programmatic) |
| **Stuck detection** | ❌ None (keeps looping) | ✅ Yes (same error 3x, no progress) |
| **Multi-repo** | ❌ No | ✅ Yes (via claw) |
| **Daily tracking** | ❌ No | ✅ Yes (daily file + report) |
| **Issue context** | ❌ No | ✅ Yes (GitHub integration) |

**What we learned from Ralph:**
- ✅ Iteration > single-pass
- ✅ Max iterations safety net
- ✅ Clear completion criteria

**What we improved:**
- ✅ Stuck detection (Ralph doesn't have this)
- ✅ Multi-issue orchestration
- ✅ Transparent tracking
- ✅ TDD-first approach

## Cost Control

### Token Budget Example

**Without iteration loop:**
```
Issue #1: 10k tokens (failed tests, committed anyway)
Issue #2: 12k tokens (failed tests, committed anyway)
Issue #3: 15k tokens (failed tests, committed anyway)
Total: 37k tokens + manual cleanup later
```

**With iteration loop:**
```
Issue #1: 10k + 8k (retry) = 18k tokens (tests pass!)
Issue #2: 12k tokens (first try success!)
Issue #3: 15k + 10k + 8k (2 retries) = 33k tokens (tests pass!)
Total: 63k tokens, all green, no cleanup needed
```

**Trade-off:** 70% more tokens upfront, but:
- No broken commits
- No manual cleanup
- No debugging time
- Higher success rate

### Safety Rails

1. **Max iterations** (default: 5) prevents runaway costs
2. **Stuck detection** stops wasted iterations
3. **Token tracking** visible in daily report
4. **Per-issue budget** can be adjusted

## Configuration

### Global Default

In `.claude/settings.json` or daily file config:
```json
{
  "max_iterations_per_issue": 5
}
```

### Per-Session Override

```bash
/auto --max-iterations-per-issue 10
```

### Per-Issue Adjustment (Future)

Could add issue-level config in GitHub labels:
```
labels: ["complex-refactor", "max-iterations:10"]
```

## Best Practices

### DO:
- ✅ Start with default (5 iterations)
- ✅ Trust stuck detection
- ✅ Review blocked issues for patterns
- ✅ Adjust based on codebase maturity

### DON'T:
- ❌ Set max iterations too high (>15) without reason
- ❌ Ignore stuck/blocked issues
- ❌ Skip test coverage (iteration only works if tests exist!)
- ❌ Override stuck detection manually

## Lead-Level Questions

### What assumption are we making?

1. **Test failures are fixable through iteration alone**
   - May need human insight for complex architectural issues

2. **5 iterations is "enough" for most issues**
   - Complex refactors might legitimately need 10-15

3. **Stuck detection heuristics are reliable**
   - Same error 3x might be too sensitive or not sensitive enough

4. **Test suite is comprehensive**
   - Passing tests = working feature (only true if coverage is good)

### What would be challenged in review?

1. **"Why not use Ralph directly?"**
   - Ralph is single-task, we need multi-issue + pivoting

2. **"70% more tokens is expensive!"**
   - But saves manual cleanup time and prevents broken commits

3. **"What if tests are flaky?"**
   - Flaky tests will trigger unnecessary iterations (test quality issue)

4. **"Same error 3x might be too strict"**
   - Some legitimate issues might take 4-5 attempts with same error class

### What future change makes this painful?

1. **E2E tests take 5+ minutes each**
   - Iteration loops become very slow
   - Mitigation: Run unit tests in loop, E2E once at end

2. **Test suites become unreliable**
   - False failures trigger unnecessary iterations
   - Mitigation: Flaky test detection

3. **External dependencies in tests**
   - API calls make tests slow/flaky
   - Mitigation: Mock external dependencies

### What would I warn the team about?

1. **Token costs can spike** if many issues get stuck
   - Solution: Start conservative, monitor daily reports

2. **Need good test coverage** for iteration to work
   - Solution: Maintain TDD discipline

3. **Stuck detection needs tuning** based on real usage
   - Solution: Review stuck patterns weekly, adjust thresholds

4. **This adds complexity** to execution logic
   - Solution: Worth it for higher success rate

## Future Enhancements (Option B)

### Pre-Issue Complexity Analysis

Before starting, estimate iteration budget:
```
IF issue has no test file:
    estimated_iterations = 5-7 (writing tests + implementation)
IF issue affects >5 files:
    estimated_iterations = 7-10 (complex refactor)
IF issue has external dependencies:
    estimated_iterations = 3-5 (higher risk of stuck)
```

### Token Budget Per Issue

Track and report:
```markdown
Issue #42 Token Usage:
- Iteration 1: 12,453 tokens
- Iteration 2: 8,721 tokens
- Iteration 3: 6,234 tokens
- Total: 27,408 tokens
```

### Adaptive Max Iterations

Learn from history:
```
IF user keeps hitting max iterations:
    suggest increasing default
IF most issues resolve in 1-2 iterations:
    suggest decreasing default
```

## Troubleshooting

### Issue keeps getting stuck

**Check:**
- Test coverage adequate?
- External dependencies mocked?
- Error messages actionable?
- Max iterations too low?

### Too many first-try failures

**Check:**
- Test suite quality
- Issue descriptions clear?
- Codebase complexity
- May need higher max iterations

### Tokens burning too fast

**Check:**
- Max iterations too high?
- Stuck detection working?
- Many blocked issues? (fix root causes)
- Consider decreasing to 3 iterations

---

## Summary

**What we built:** Ralph Wiggum-inspired iteration loop integrated into `/auto` execution phase.

**Key features:**
- Test-until-green approach (no broken commits)
- Stuck detection (prevents runaway costs)
- Transparent tracking (see what's happening)
- TDD-first (aligns with core rules)

**Value proposition:** Higher success rate, no broken commits, better visibility into blockers.

**Trade-off:** More tokens upfront, but saves manual cleanup time and prevents technical debt.

**This is a judgment call.** We're betting that iteration cost is worth the quality improvement. Early feedback will validate or challenge this.
