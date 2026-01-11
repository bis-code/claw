# /auto

**One command to rule them all.** AI discovers, plans, executes, and ships - or just plans if you prefer.

## Defaults

| Setting | Default | Description |
|---------|---------|-------------|
| **Mode** | **full** | Complete cycle: discover → plan → execute → ship |
| `--hours` | **4** | Work budget (human-equivalent work, not wall-clock time) |
| `--discovery` | **shallow** | Quick scan (TODOs + recent changes) |
| `--focus` | *none* | All areas (optional to specify) |

> **Just run `/auto`** and Claude works on 4h worth of tasks, then ships and reports.

## What This Skill Does

**IMPORTANT:** `/auto` runs a COMPLETE cycle by default. It does NOT stop after planning.

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ DISCOVER │───▶│ CONTEXT  │───▶│ EXECUTE  │───▶│   SHIP   │───▶│  REPORT  │
│ (phase1) │    │ (phase2) │    │(phase5)  │    │(phase6)  │    │          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     │               │                │
     ▼               ▼                ▼
 Creates      Reads yesterday    Works on all
 new issues   & patterns         prioritized tasks
```

1. **Discovers** work by analyzing the codebase (creates GitHub issues)
2. **Reads context** from yesterday's wind-down notes (priorities, blockers, energy)
3. **Aggregates** discovered + existing + yesterday's unfinished work
4. **Brainstorms** with multi-agent planning on ALL issues
5. **Executes** implementations with TDD (works through the queue)
6. **Ships** completed work (creates PRs, closes issues)
7. **Reports** with full summary of discovered + completed items

**Time budget applies to the ENTIRE cycle**, not just execution.

## Understanding the --hours Flag

**Important:** The `--hours` parameter represents **work output** (human-equivalent), not wall-clock time.

Claude typically completes work significantly faster than humans due to:
- No typing delays or context switching
- Instant reasoning and code generation
- Only bottlenecks are external processes (tests, git operations, API calls)

**However, actual runtime varies widely based on:**
- Test suite speed (unit tests vs E2E tests)
- Build processes
- External API latency
- Codebase size and complexity

We don't make specific time promises. The `--hours` flag helps Claude prioritize and scope work, not predict how long it will take.

## Invocation

### Basic Usage

```bash
/auto                           # Prompts for mode, then runs full cycle (4 hours)
/auto --plan-only               # ONLY discover and plan, then stop (no execution)
/auto --skip-discovery          # Skip discovery, plan and execute existing issues only
```

### Interactive Mode Selection

When you run `/auto` without specifying a discovery mode, you'll be prompted:

```
🔍 Discovery Mode

Choose discovery depth for this session:

1. Shallow - Fast scan (~55k tokens)
   ✓ Quick daily scan, familiar codebase
   ✗ May miss deep issues

2. Balanced - Smart mix (~120k tokens) ⭐ Recommended
   ✓ High quality where it matters
   ✓ Efficient for routine tasks
   ✓ Good for regular development

3. Deep - Thorough audit (~450k tokens)
   ✓ Maximum thoroughness
   ✓ Weekly/monthly audit
   ✗ Heavy for daily use

Select [1-3] (default: 2):
```

**Implementation:** Use AskUserQuestion tool:

```python
# When /auto is invoked without --discovery flag
if not discovery_mode_specified:
    response = AskUserQuestion(
        questions=[{
            "question": "Choose discovery depth for this session:",
            "header": "Discovery",
            "multiSelect": false,
            "options": [
                {
                    "label": "Shallow - Fast scan (~55k tokens)",
                    "description": "Quick daily scan. May miss deep issues but good for familiar codebases."
                },
                {
                    "label": "Balanced - Smart mix (~120k tokens) (Recommended)",
                    "description": "High quality where it matters, efficient for routine tasks. Best for regular development."
                },
                {
                    "label": "Deep - Thorough audit (~450k tokens)",
                    "description": "Maximum thoroughness. Use for weekly/monthly audits or critical reviews."
                }
            ]
        }]
    )

    # Then show confirmation
    print(f"✓ {selected_mode} mode selected")
    print("\nDiscovery agents:")
    for agent in agents_for_mode(selected_mode):
        print(f"  • {agent.name} ({agent.model}, ~{agent.tokens}k tokens)")

    print(f"\nEstimated: ~{total_tokens}k tokens")
    print("\nContinue? [Y/n]")
```

### Skip the Prompt (Direct Mode)

If you already know which mode you want:

```bash
/auto --discovery shallow    # Fast & cheap, no prompt
/auto --discovery balanced   # Smart mix, no prompt
/auto --discovery deep       # Thorough, no prompt
/auto --skip-discovery       # No discovery at all
```

### Advanced Usage

```bash
/auto --hours 8                         # Extended work budget (8h human-equivalent)
/auto --focus "billing"                 # Focus discovery + execution on billing area
/auto --discovery deep --hours 8        # Thorough scan with extended work budget
/auto --max-iterations-per-issue 10     # Allow up to 10 attempts per issue (default: 5)
```

### Key Distinctions

| Command | Discovery | Planning | Execution | Shipping |
|---------|-----------|----------|-----------|----------|
| `/auto` | ✅ | ✅ | ✅ | ✅ |
| `/auto --plan-only` | ✅ | ✅ | ❌ | ❌ |
| `/auto --skip-discovery` | ❌ | ✅ | ✅ | ✅ |

**Aliases:**
- `/plan-day` → `/auto --plan-only` (backwards compatibility)

---

## Phase 1: Discovery

### Discovery Agents (Parallel)

**⚠️ Smart Model Selection (Balanced Mode - Default):**

The key insight: **Not all discovery tasks need Sonnet's advanced reasoning.**

| Agent | Default Model | Why | Can Use Haiku? |
|-------|---------------|-----|----------------|
| TODO Scanner | **Haiku** | Just grep + parse | ✅ Yes - mechanical task |
| Dependency Check | **Haiku** | Just run commands | ✅ Yes - mechanical task |
| Test Coverage | **Haiku** | Just find missing tests | ✅ Yes - pattern matching |
| Code Quality | **Sonnet** | Needs reasoning about complexity | ⚠️ Maybe - depends on depth |
| Security Scan | **Sonnet** | Needs threat modeling | ❌ No - needs sophistication |

**This is the "balanced" approach:**
- Use cheap model (Haiku) for mechanical tasks (60% of work)
- Use smart model (Sonnet) for reasoning tasks (40% of work)
- **Result: ~120k tokens instead of 450k or 40k**
- **Quality: High where it matters, efficient elsewhere**

**Per-mode configuration:**

**Shallow mode:**
- All agents: Haiku
- Limits: head_limit: 10, max_turns: 3
- Budget: ~8k per agent
- Total: ~40k tokens

**Balanced mode (default):**
- Mechanical agents: Haiku (TODO, deps, test coverage)
- Reasoning agents: Sonnet (security, code quality)
- Limits: head_limit: 20, max_turns: 5
- Budget: 15-30k per agent (varies by model)
- Total: ~120k tokens

**Deep mode:**
- All agents: Sonnet with ultrathink
- Limits: No limits, max_turns: 10
- Budget: 60-100k per agent
- Total: ~450k tokens

```
┌─────────────────────────────────────────────────────────────────┐
│  TODO Scanner Agent (Haiku, max_turns: 3)                      │
│  ─────────────────                                              │
│  grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.go" --include="*.ts" │
│  ├─ Use: head_limit: 10 (not unlimited!)                       │
│  ├─ Use: files_with_matches mode                               │
│  └─ Don't read full files during discovery                     │
│                                                                  │
│  Finds: Deferred work, known issues, technical shortcuts        │
│  Creates: Issue for each significant TODO                       │
│  **Target: 5-10k tokens** (not 60k!)                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Test Coverage Agent (Haiku, max_turns: 3)                     │
│  ───────────────────                                            │
│  ├─ Use: Glob with limit 20 files                              │
│  ├─ Don't read file contents during discovery                  │
│  └─ Just identify: Files without _test.go or .spec.ts         │
│                                                                  │
│  Creates: Issues for coverage gaps                              │
│  **Target: 5-10k tokens** (not 70k!)                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Code Quality Agent (Haiku, max_turns: 3)                      │
│  ─────────────────                                              │
│  ├─ Use: head_limit: 5 on all searches                         │
│  ├─ Skip: Detailed code analysis (too expensive)               │
│  └─ Just count: Lines per function (via Grep -c)              │
│                                                                  │
│  Creates: Tech debt issues for obvious problems                 │
│  **Target: 5-10k tokens** (not 90k!)                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Security Agent (Haiku, max_turns: 3) ⚠️ MOST EXPENSIVE        │
│  ─────────────                                                  │
│  ├─ Use: Grep with head_limit: 5 (was doing 49 tool uses!)    │
│  ├─ Focus: High-signal patterns only                           │
│  │   - password|secret|key in code (not comments)             │
│  │   - SQL string concatenation                                │
│  └─ Skip: Deep vulnerability analysis (use dedicated tools)    │
│                                                                  │
│  Creates: Security issues (high priority)                       │
│  **Target: 5-10k tokens** (not 93k!)                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Dependency Agent (Haiku, max_turns: 2)                        │
│  ───────────────                                                │
│  ├─ Just run: npm outdated, go list -m -u all                 │
│  └─ Parse output, create issues                                │
│                                                                  │
│  Creates: Dependency update issues                              │
│  **Target: 3-5k tokens** (not 30k!)                            │
└─────────────────────────────────────────────────────────────────┘
```

### Discovery Output Format

Each discovery agent creates issues like:

```bash
gh issue create \
  --title "[Auto] TODO: Implement retry logic in pipeline" \
  --label "claude-ready,auto-discovered,P2-medium" \
  --body "## Discovered By
AI Discovery Agent (TODO Scanner)

## Source
File: apps/highlights-api/internal/worker/pipeline/pipeline.go
Line: 142

## Context
\`\`\`go
// TODO: Add retry logic here
\`\`\`

## Suggested Approach
Implement exponential backoff with max 3 retries.

## Estimated Scope
S (30 min - 2 hours)

## Test Strategy
Unit tests only"
```

### Token Optimization Summary

**Problem:** Original unoptimized implementation used ~450k tokens for discovery + brainstorm!

**Solution:** Three modes to balance token usage vs quality

| Mode | Discovery | Brainstorm | Total | Quality |
|------|-----------|------------|-------|---------|
| **Deep** | 352k (Sonnet, unlimited) | 98k (Sonnet, all) | **450k** | ⭐⭐⭐⭐⭐ Most thorough |
| **Balanced** ⭐ | 80k (Smart mix) | 40k (Smart mix) | **120k** | ⭐⭐⭐⭐ High quality, efficient |
| **Shallow** | 30k (Haiku, limited) | 25k (Haiku, skip simple) | **55k** | ⭐⭐⭐ Good for quick scans |

**Balanced mode breakdown (recommended default):**

| Agent | Model | Tokens | Rationale |
|-------|-------|--------|-----------|
| TODO Scanner | Haiku | 8k | Mechanical - just grep + parse |
| Test Coverage | Haiku | 8k | Mechanical - pattern matching |
| Dependency | Haiku | 5k | Mechanical - run commands |
| **Code Quality** | **Sonnet** | **30k** | **Reasoning - complexity analysis** |
| **Security** | **Sonnet** | **30k** | **Reasoning - threat modeling** |
| **Discovery Total** | - | **~80k** | **Smart mix (60% Haiku, 40% Sonnet)** |

**Brainstorm (balanced):**
- Simple issues (TODOs, deps): Skip or Haiku (5k each)
- Complex issues (security, arch): Sonnet (15k each)
- Total: ~40k tokens

**Balanced mode total: ~120k tokens (73% reduction from deep, but maintains quality where it matters)**

---

## Phase 2: Read Yesterday's Context

**Purpose**: Provide continuity and learn from previous day's work.

**Same implementation as `/plan-day` Step 2**:
- Check for yesterday's wind-down note (Obsidian or ~/.claw/daily/)
- Parse: Tomorrow's Priorities, Focus Stealers, Energy Level, Work Done
- Display context to user
- Optional: Multi-day pattern analysis with `--patterns`

**Auto-pilot specific usage**:
```markdown
📖 Context from yesterday:

**Yesterday's unfinished priorities:**
- [ ] Review PR #42
- [ ] Write tests for auth module

**These will be considered in discovery prioritization.**

Continue? (yes/no)
```

**Integration with Discovery**:
- Unfinished priorities from yesterday → elevated to P1
- Recurring blockers → flagged in discovery report
- Energy trends → influence time budget allocation

**Edge Cases**: Same as `/plan-day` - gracefully handle missing notes.

---

## Phase 3: Aggregate & Prioritize

**ultrathink:** Apply comprehensive reasoning to analyze all discovered and existing issues, evaluate dependencies, and create an optimal execution strategy.

**This phase happens IMMEDIATELY after discovery and context reading** (unless `--discover-only`).

After discovery, the orchestrator:

1. **Fetches all issues from ALL tracked repos** (existing + just created)
2. **Deduplicates** (don't create issue for something already tracked)
3. **Prioritizes** based on:
   - Security issues → P0 (do today)
   - Test coverage gaps on critical paths → P1
   - Tech debt in active areas → P2
   - TODOs and minor improvements → P3
4. **Passes prioritized list to execution phase** (no user intervention)

**Multi-repo aggregation:**

If running via `claw`:
```bash
# Fetches from ALL tracked repos (current + claw repos list)
claw issues --label "claude-ready" --json
```

If running via `claude` directly:
```bash
# Current repo only (fallback)
CURRENT_REPO=$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
gh issue list --repo "$CURRENT_REPO" --label "claude-ready" --state open \
  --json number,title,labels,body,repository
```

**Cross-repo discovery:** When working with multiple repos, discovery agents run
in the current working directory but issues can be created in any tracked repo.
The aggregator groups issues by repository for prioritization.

---

## Phase 4: Brainstorm

**⚠️ Token Optimization:**
- Use **Haiku model** for all brainstorm agents (was using Sonnet!)
- Set `max_turns: 2` to limit analysis depth
- **Skip brainstorm for obvious issues** (TODOs, simple test additions)
- Only brainstorm complex/ambiguous issues (security, architecture, UX)
- **Budget: ~5k tokens per agent** (not 20k!)

Invokes `/brainstorm` with **complex issues only** (skip obvious ones):

**When to brainstorm:**
- ✅ Security issues (need CTO + QA input)
- ✅ Architectural changes (need CTO + Senior Dev)
- ✅ User-facing features (need Product + UX)
- ❌ Simple TODOs (skip brainstorm, just do it)
- ❌ Test additions (skip brainstorm, obvious what's needed)
- ❌ Dependency updates (skip brainstorm, just update)

**Agents (Haiku, max_turns: 2):**
- Senior Developer analyzes implementation approaches
- Product Owner validates priority ordering
- CTO reviews architectural implications
- QA validates test strategies
- UX checks user-facing changes

Output: Prioritized plan for today

**Original cost:** ~98k tokens (5 agents × 20k)
**Optimized cost:** ~25k tokens (Haiku + max_turns: 2 + skip simple issues)

---

## Phase 5: Execute

The **Senior Developer Agent** takes over with **iteration-until-green** approach:

```
┌─────────────────────────────────────────────────────────────────┐
│  For each issue in today's plan:                                │
│                                                                  │
│  1. Read issue details                                          │
│  2. Analyze codebase context                                    │
│  3. Generate completion criteria checklist                      │
│  4. ITERATION LOOP (max 5 attempts by default):                 │
│     a. Write tests first (TDD)                                  │
│     b. Implement solution                                       │
│     c. Run full test suite                                      │
│     d. Check linter (if applicable)                             │
│     e. IF all tests pass AND no lint errors:                    │
│        → Exit loop (SUCCESS)                                    │
│     f. ELSE:                                                    │
│        → Analyze failures                                       │
│        → Check for stuck conditions                             │
│        → If stuck: log blocker, exit loop (STUCK)               │
│        → Otherwise: iteration++, continue loop                  │
│  5. Commit with issue reference (only if SUCCESS)               │
│  6. Mark issue done or blocked                                  │
│  7. Move to next issue                                          │
│                                                                  │
│  The QA Agent validates after each issue:                       │
│  - Tests actually cover the changes                             │
│  - No regressions introduced                                    │
│  - Edge cases handled                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Execution Loop (Iteration-Until-Green)

**Key Innovation:** Ralph Wiggum-inspired persistence - don't settle for "good enough", iterate until truly done.

```
while issues_remaining and time_remaining:
    issue = pick_next_issue()
    iteration = 0
    max_iterations = 5  # Configurable via --max-iterations-per-issue
    stuck = false
    last_error = null
    error_count = {}

    # Initialize completion criteria
    completion_criteria = generate_criteria(issue)

    # Iteration loop - keep trying until success or stuck
    while iteration < max_iterations and not stuck:
        iteration++

        # Senior Dev implements/fixes
        senior_dev.work(issue, iteration)

        # Run tests
        test_result = run_tests()
        lint_result = run_linter()

        # Check for success
        if test_result.all_pass and lint_result.no_errors:
            log_iteration_success(issue, iteration)
            commit(issue)
            mark_done(issue)
            break  # Exit iteration loop - SUCCESS

        # Analyze failure
        current_error = extract_error(test_result, lint_result)

        # Stuck detection (same error 3 times)
        if error_count[current_error]:
            error_count[current_error]++
            if error_count[current_error] >= 3:
                stuck = true
                log_stuck(issue, current_error, "Same error 3 times")
                mark_blocked(issue, current_error)
                break  # Exit iteration loop - STUCK
        else:
            error_count[current_error] = 1

        # Stuck detection (no file changes)
        if iteration > 1 and no_files_changed():
            stuck = true
            log_stuck(issue, current_error, "No file changes")
            mark_blocked(issue, "No progress - files unchanged")
            break  # Exit iteration loop - STUCK

        # Log iteration failure
        log_iteration_failure(issue, iteration, current_error)

        # If max iterations reached
        if iteration >= max_iterations:
            log_max_iterations(issue, max_iterations)
            mark_blocked(issue, "Max iterations reached")
            break  # Exit iteration loop - MAX ITERATIONS

    # Move to next issue
    next_issue()
```

### Stuck Detection Rules

To prevent token waste on impossible issues:

| Condition | Threshold | Action |
|-----------|-----------|--------|
| **Same error repeated** | 3 times | Mark STUCK, log blocker, move on |
| **No file changes** | 2 iterations | Mark STUCK, log "no progress", move on |
| **Max iterations** | 5 (default) | Mark BLOCKED, log attempts, move on |

**Philosophy:** It's better to identify blockers quickly and move to productive work than to waste tokens on impossible issues.

### Interruption Handling

During execution, if the Senior Dev agent encounters a blocker:

```
┌─────────────────────────────────────────────────────────────────┐
│  Senior Dev: "I'm stuck on #42. The payment modal needs        │
│              a component that doesn't exist yet."               │
│                                                                  │
│  Options:                                                       │
│  1. Create prerequisite issue, defer #42                        │
│  2. Implement prerequisite inline (scope increase)              │
│  3. Ask for human input                                         │
│                                                                  │
│  Auto-decision: If prerequisite is < 1 hour, do inline.        │
│                 Otherwise, create issue and move on.            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 6: Ship

Invokes `/ship-day`:

1. Squash commits into themed groups
2. Create PR with full summary
3. Close all completed issues
4. Update deferred issues with comments

---

## Configuration

### Hours Budget (Default: 4)

```bash
/auto              # 4h work budget (human-equivalent)
/auto --hours 8    # 8h work budget (human-equivalent)
/auto --hours 2    # 2h work budget (human-equivalent)
```

**How the budget works:**
- Budget represents **work output** (human-equivalent hours), not wall-clock time
- Claude stops when the work budget is exhausted, then auto-ships
- Actual wall-clock time varies based on test suite speed and external processes

### Max Iterations Per Issue (Default: 5)

```bash
/auto --max-iterations-per-issue 5    # Default: conservative cost control
/auto --max-iterations-per-issue 10   # For complex issues
/auto --max-iterations-per-issue 3    # For well-understood codebases
```

**How it works:**
- Each issue gets up to N attempts to pass all tests
- Prevents runaway token costs on impossible issues
- Combines with stuck detection (same error 3x, no file changes)
- Failed issues are marked as BLOCKED with blocker details logged

**When to increase:**
- Complex refactors (10-15 iterations)
- New codebases with unfamiliar patterns
- Issues involving external dependencies

**When to decrease:**
- Well-tested, familiar codebase (3 iterations often enough)
- Token budget constraints
- Quick daily maintenance work

### Focus Area (Optional)

```bash
/auto --focus "billing"
```

Only discovers and works on billing-related files. If not specified, works on all areas.

### Discovery Depth (Default: balanced)

```bash
/auto                        # Uses default balanced discovery
/auto --discovery shallow    # Fast & cheap (Haiku, limit 10, ~40k tokens)
/auto --discovery balanced   # Smart mix (default, ~120k tokens)
/auto --discovery deep       # Thorough & expensive (Sonnet, unlimited, ~450k tokens)
/auto --skip-discovery       # Skip discovery, use existing issues only
```

**Mode comparison:**

| Mode | Model | Result Limit | max_turns | Tokens | When to Use |
|------|-------|--------------|-----------|--------|-------------|
| **shallow** | Haiku | 10 | 3 | ~40k | Quick daily scan, known codebase |
| **balanced** | Haiku for simple<br>Sonnet for complex | 20 | 5 | ~120k | **Default** - good quality/efficiency balance |
| **deep** | Sonnet | Unlimited | 10 | ~450k | Weekly audit, new codebase, thorough review |

**What changes per mode:**

**Shallow (Fast):**
- ✅ Good for: Daily maintenance, known codebase
- ❌ Might miss: Deep issues, subtle security problems
- Model: All Haiku
- Limits: 10 results, 3 turns
- Brainstorm: Skip simple issues, Haiku for rest

**Balanced (Recommended Default):**
- ✅ Good for: Regular development, most use cases
- ✅ Smart model selection:
  - Haiku for: TODO scanning, dependency checks (mechanical)
  - Sonnet for: Security analysis, code quality (needs reasoning)
- Limits: 20 results, 5 turns
- Brainstorm: Haiku for simple issues, Sonnet for complex

**Deep (Thorough):**
- ✅ Good for: Weekly audits, new codebase exploration, pre-release review
- ✅ Most thorough analysis possible
- Model: All Sonnet (with ultrathink)
- Limits: Unlimited results, 10 turns
- Brainstorm: All issues, Sonnet for all agents

---

## Safety Rails

### Human Checkpoints

Even in full autonomous mode, pause for human input on:

- Security-critical changes (auth, payments)
- Database migrations
- Breaking API changes
- Deletions of significant code

```
┌─────────────────────────────────────────────────────────────────┐
│  ⚠️  CHECKPOINT: Security-Critical Change                       │
│                                                                  │
│  Issue #47 involves auth token handling.                        │
│  Proposed change: Modify JWT validation logic.                  │
│                                                                  │
│  Continue? [y/n/review]                                         │
└─────────────────────────────────────────────────────────────────┘
```

### Rollback Capability

Before starting execution:

```bash
git tag auto-start-$(date +%Y%m%d-%H%M)
```

If anything goes wrong:

```bash
git reset --hard auto-start-$(date +%Y%m%d-%H%M)
```

### Rate Limits

- Max 10 issues created per session
- Max 20 commits per day
- Pause after 5 issues completed for human review

---

## Daily Report

At the end of `/auto`, generate a report:

```markdown
# Auto Report: 2025-12-30

## Summary
- Work completed: 4 hours (human-equivalent)
- Issues discovered: 7
- Issues completed: 4
- Issues blocked: 1
- Issues deferred: 0
- PR created: #123

## Execution Statistics
- Total iterations: 12 (avg 3.0 per completed issue)
- First-try successes: 1 (25%)
- Required retries: 3 (75%)
- Stuck/blocked: 1 (max iterations reached)

## Discoveries
| Issue | Type | Source | Status | Iterations |
|-------|------|--------|--------|-----------|
| #51 | TODO | pipeline.go:142 | Completed ✅ | 2/5 |
| #52 | Test Gap | billing_handler.go | Completed ✅ | 1/5 |
| #53 | Security | auth.go | Completed ✅ | 4/5 |
| #54 | Tech Debt | stripe.go | Blocked 🚫 | 5/5 (STUCK) |

### Detailed Execution Log

#### Issue #51: Add retry logic to pipeline ✅
- **Iterations:** 2/5
- **Exit reason:** All tests passing
- **Iteration breakdown:**
  1. Initial implementation → Tests failed (missing error handling)
  2. Added error handling → ✅ All tests passing

#### Issue #52: Test coverage for billing_handler ✅
- **Iterations:** 1/5
- **Exit reason:** All tests passing (first try!)
- **Iteration breakdown:**
  1. Implemented tests → ✅ All tests passing

#### Issue #53: Fix auth token vulnerability ✅
- **Iterations:** 4/5
- **Exit reason:** All tests passing
- **Iteration breakdown:**
  1. Initial fix → Tests failed (missing validation)
  2. Added validation → Tests failed (edge case with expired tokens)
  3. Fixed expiry handling → Tests failed (race condition)
  4. Added locking → ✅ All tests passing

#### Issue #54: Tech debt in stripe.go 🚫 BLOCKED
- **Iterations:** 5/5
- **Exit reason:** Max iterations reached
- **Blocker:** External Stripe API returning 404 on webhook endpoint
- **Needs human:** Verify Stripe webhook configuration in dashboard
- **Iteration breakdown:**
  1. Refactored Stripe client → Tests failed (404 on webhook)
  2. Updated endpoint URL → Tests failed (same 404)
  3. Added debug logging → Tests failed (404 persists)
  4. Checked Stripe config → Tests failed (404 persists)
  5. Max iterations → Gave up

## Agent Activity

### Senior Developer
- Implemented 4 issues
- 847 lines added, 123 removed
- Average iterations per issue: 3.0
- Average work per issue: 1h human-equivalent

### QA Engineer
- Validated 4 implementations
- Identified 8 edge cases during iteration
- All completed issues have green tests

### Discovery Agents
- TODOs found: 12 (7 significant)
- Coverage gaps: 3 files
- Security issues: 1 (fixed)

## Insights
- **Iteration patterns:** Most issues resolved in 2-4 attempts
- **Stuck issue:** #54 blocked by external dependency (Stripe config)
- **First-try success:** Only 25% succeeded without iteration (normal)
- **Value of iteration:** 75% of issues needed refinement to pass tests
- Billing area has most tech debt (3 issues)
- Auth token handling was vulnerable (fixed in #54 after 4 iterations)

## Tomorrow's Candidates
- #54: Tech debt in stripe.go (UNBLOCK: Check Stripe webhook config)
- #55: Test coverage for webhooks
- #56: TODO in scheduler
```

---

## Integration with Other Commands

```bash
/auto                         # Full autonomous day: discover → plan → execute → ship
/auto --plan-only             # Planning only (same as legacy /plan-day)
/plan-day                     # Alias for /auto --plan-only (backwards compatibility)
```

**Internal Skills (Hidden from Users):**
- `/brainstorm` - Multi-agent planning (called by `/auto` internally)
- `/autonomous` - Execution loop (called by `/auto` internally)

**How They Integrate:**
- `/auto` orchestrates discovery, then calls `/brainstorm` for planning, then `/autonomous` for execution
- `/auto --plan-only` runs discovery and `/brainstorm`, then stops
- Human can interrupt at any point with `/pivot`

**Recommendation for Users:**
- Use `/auto` for everything - it's intelligent by default
- Only use flags when you need specific behavior (e.g., planning-only mode)
