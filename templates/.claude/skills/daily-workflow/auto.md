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

1. Shallow - Fast & cheap (~55k tokens, $0.14)
   ✓ Quick daily scan, familiar codebase
   ✗ May miss deep issues

2. Balanced - Smart mix (~120k tokens, $0.36) ⭐ Recommended
   ✓ High quality where it matters
   ✓ Efficient for routine tasks
   ✓ Good for regular development

3. Deep - Thorough audit (~450k tokens, $1.35)
   ✓ Maximum thoroughness
   ✓ Weekly/monthly audit
   ✗ Expensive for daily use

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
                    "label": "Shallow - Fast & cheap ($0.14)",
                    "description": "Quick daily scan, ~55k tokens. May miss deep issues but good for familiar codebases."
                },
                {
                    "label": "Balanced - Smart mix ($0.36) (Recommended)",
                    "description": "High quality where it matters, efficient for routine tasks. Best for regular development. ~120k tokens."
                },
                {
                    "label": "Deep - Thorough audit ($1.35)",
                    "description": "Maximum thoroughness, ~450k tokens. Use for weekly/monthly audits or critical reviews."
                }
            ]
        }]
    )

    # Then show confirmation
    print(f"✓ {selected_mode} mode selected")
    print("\nDiscovery agents:")
    for agent in agents_for_mode(selected_mode):
        print(f"  • {agent.name} ({agent.model}, ~{agent.tokens}k tokens)")

    print(f"\nEstimated: ~{total_tokens}k tokens, ${total_cost}")
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
/auto --hours 8                   # Extended work budget (8h human-equivalent)
/auto --focus "billing"           # Focus discovery + execution on billing area
/auto --discovery deep --hours 8  # Thorough scan with extended work budget
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

**Solution:** Three modes to balance cost vs quality

| Mode | Discovery | Brainstorm | Total | Cost | Quality |
|------|-----------|------------|-------|------|---------|
| **Deep** | 352k (Sonnet, unlimited) | 98k (Sonnet, all) | **450k** | $1.35 | ⭐⭐⭐⭐⭐ Most thorough |
| **Balanced** ⭐ | 80k (Smart mix) | 40k (Smart mix) | **120k** | $0.36 | ⭐⭐⭐⭐ High quality, reasonable cost |
| **Shallow** | 30k (Haiku, limited) | 25k (Haiku, skip simple) | **55k** | $0.14 | ⭐⭐⭐ Good for quick scans |

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

The **Senior Developer Agent** takes over:

```
┌─────────────────────────────────────────────────────────────────┐
│  For each issue in today's plan:                                │
│                                                                  │
│  1. Read issue details                                          │
│  2. Analyze codebase context                                    │
│  3. Write tests first (TDD)                                     │
│  4. Implement solution                                          │
│  5. Run tests, fix failures                                     │
│  6. Commit with issue reference                                 │
│  7. Mark issue done, move to next                               │
│                                                                  │
│  The QA Agent validates after each issue:                       │
│  - Tests actually cover the changes                             │
│  - No regressions introduced                                    │
│  - Edge cases handled                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Execution Loop

```
while issues_remaining and time_remaining:
    issue = pick_next_issue()

    # Senior Dev implements
    senior_dev.implement(issue)

    # QA validates
    qa_result = qa.validate(issue)

    if qa_result.needs_work:
        senior_dev.fix(qa_result.feedback)

    commit(issue)
    mark_done(issue)
```

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

| Mode | Model | Result Limit | max_turns | Tokens | Cost | When to Use |
|------|-------|--------------|-----------|--------|------|-------------|
| **shallow** | Haiku | 10 | 3 | ~40k | $0.01 | Quick daily scan, known codebase |
| **balanced** | Haiku for simple<br>Sonnet for complex | 20 | 5 | ~120k | $0.36 | **Default** - good quality/cost balance |
| **deep** | Sonnet | Unlimited | 10 | ~450k | $1.35 | Weekly audit, new codebase, thorough review |

**What changes per mode:**

**Shallow (Fast & Cheap):**
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
- Issues deferred: 1
- PR created: #123

## Discoveries
| Issue | Type | Source | Status |
|-------|------|--------|--------|
| #51 | TODO | pipeline.go:142 | Completed |
| #52 | Test Gap | billing_handler.go | Completed |
| #53 | Tech Debt | stripe.go | Deferred |
| #54 | Security | auth.go | Completed |

## Agent Activity

### Senior Developer
- Implemented 4 issues
- 847 lines added, 123 removed
- Average work per issue: 1h human-equivalent

### QA Engineer
- Validated 4 implementations
- Requested fixes on 2
- All tests passing

### Discovery Agents
- TODOs found: 12 (7 significant)
- Coverage gaps: 3 files
- Security issues: 1 (fixed)

## Insights
- Billing area has most tech debt (3 issues)
- Pipeline code needs retry logic (created #51)
- Auth token handling was vulnerable (fixed in #54)

## Tomorrow's Candidates
- #53: Tech debt in stripe.go
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
