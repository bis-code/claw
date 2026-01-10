# /auto-pilot

Fully autonomous development mode. AI discovers, plans, executes, and ships.

## Defaults

| Setting | Default | Description |
|---------|---------|-------------|
| `--hours` | **4** | Time budget for ENTIRE cycle (discovery + execution) |
| `--discovery` | **shallow** | Quick scan (TODOs + recent changes) |
| `--focus` | *none* | All areas (optional to specify) |

> **Just run `/auto-pilot`** and Claude works for 4 hours, then ships and reports.

## What This Skill Does

**IMPORTANT:** Auto-pilot runs a COMPLETE cycle by default. It does NOT stop after discovery.

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

## Invocation

```
/auto-pilot                      # Full cycle: discover → execute → ship (4 hours)
/auto-pilot --hours 8            # Extended 8-hour session
/auto-pilot --discover-only      # ONLY discover, create issues, then stop
/auto-pilot --focus "billing"    # Focus discovery + execution on billing area
/auto-pilot --discovery deep     # Full codebase scan (then execute)
/auto-pilot --discovery none     # Skip discovery, execute existing issues only
```

**Key distinction:**
- Default: Discovers work, creates issues, then EXECUTES them
- `--discover-only`: Creates issues but does NOT execute (for planning ahead)

---

## Phase 1: Discovery

### Discovery Agents (Parallel)

```
┌─────────────────────────────────────────────────────────────────┐
│  TODO Scanner Agent                                             │
│  ─────────────────                                              │
│  grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.go" --include="*.ts" │
│                                                                  │
│  Finds: Deferred work, known issues, technical shortcuts        │
│  Creates: Issue for each significant TODO                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Test Coverage Agent                                            │
│  ───────────────────                                            │
│  Analyzes:                                                      │
│  - Files without corresponding _test.go or .spec.ts            │
│  - Functions with no test coverage                              │
│  - Critical paths without E2E tests                            │
│                                                                  │
│  Creates: Issues for coverage gaps                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Code Quality Agent                                             │
│  ─────────────────                                              │
│  Looks for:                                                     │
│  - Functions > 50 lines (complexity)                           │
│  - Duplicated code patterns                                     │
│  - Inconsistent error handling                                  │
│  - Missing input validation                                     │
│                                                                  │
│  Creates: Tech debt issues                                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Security Agent                                                 │
│  ─────────────                                                  │
│  Scans for:                                                     │
│  - Hardcoded secrets/credentials                               │
│  - SQL injection patterns                                       │
│  - XSS vulnerabilities                                          │
│  - Missing auth checks                                          │
│                                                                  │
│  Creates: Security issues (high priority)                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Dependency Agent                                               │
│  ───────────────                                                │
│  Checks:                                                        │
│  - npm outdated                                                 │
│  - go list -m -u all                                           │
│  - Security advisories                                          │
│                                                                  │
│  Creates: Dependency update issues                              │
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

Invokes `/brainstorm` with all issues (existing + discovered + yesterday's unfinished):

- Senior Developer analyzes implementation approaches
- Product Owner validates priority ordering
- CTO reviews architectural implications
- QA validates test strategies
- UX checks user-facing changes

Output: Prioritized plan for today

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

```
/auto-pilot              # Uses default 4-hour budget
/auto-pilot --hours 8    # Extended 8-hour session
/auto-pilot --hours 2    # Short 2-hour sprint
```

Stops discovery/execution when time budget exhausted, then auto-ships.

### Focus Area (Optional)

```
/auto-pilot --focus "billing"
```

Only discovers and works on billing-related files. If not specified, works on all areas.

### Discovery Depth (Default: shallow)

```
/auto-pilot                     # Uses default shallow discovery
/auto-pilot --discovery deep    # Full codebase scan (longer)
/auto-pilot --discovery shallow # Just TODOs and recent changes (default)
/auto-pilot --discovery none    # Skip discovery, use existing issues only
```

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
git tag auto-pilot-start-$(date +%Y%m%d-%H%M)
```

If anything goes wrong:

```bash
git reset --hard auto-pilot-start-$(date +%Y%m%d-%H%M)
```

### Rate Limits

- Max 10 issues created per session
- Max 20 commits per day
- Pause after 5 issues completed for human review

---

## Daily Report

At the end of `/auto-pilot`, generate a report:

```markdown
# Auto-Pilot Report: 2025-12-30

## Summary
- Duration: 4 hours
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
- Average time per issue: 45 min

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

## Integration

```
/auto-pilot                   # Full autonomous day
/plan-day --brainstorm        # Planning with multi-agent
/brainstorm                   # Just brainstorm
/plan-day                     # Simple single-agent planning
```

The skills build on each other:
- `/auto-pilot` calls `/brainstorm` which calls planning logic
- Discovery agents can be run standalone or as part of auto-pilot
- Human can interrupt at any point with `/pivot`
