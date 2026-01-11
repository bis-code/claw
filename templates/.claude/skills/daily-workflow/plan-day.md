# /plan-day

> **Note:** `/plan-day` is now an alias for `/auto --plan-only`. For full autonomous execution, use `/auto` instead.

Time-boxed daily planning with lens-enforced decision making.

## Philosophy

You are a single reasoning agent applying explicit decision lenses.
You do NOT roleplay roles or simulate conversations.
You apply lenses to improve decision quality and surface trade-offs.

## What This Skill Does

1. Takes available hours as input
2. Fetches GitHub issues OR asks what to work on
3. Applies mandatory lenses to each candidate
4. Surfaces conflicts explicitly
5. Forces decision outcomes (build/defer/reject/modify)
6. Creates daily branch and state file on approval

## Invocation

### Direct (Legacy)
```bash
/plan-day --hours 4              # Plan for 4 hours
/plan-day --hours 6 --brainstorm # Full multi-agent analysis
/plan-day --hours 2 --no-issues  # Manual input mode
```

### Via /auto (Recommended)
```bash
/auto --plan-only                # Uses default 4 hours
/auto --plan-only --hours 6      # Custom time budget
/auto --plan-only --focus "billing"  # Focus on specific area
```

---

## Decision Lenses (Mandatory)

Lenses are NOT optional. Apply them explicitly for each candidate.

### Value Lens
Questions to answer:
- Who benefits from this? (user/business/developer)
- What metric does it move? (conversion, retention, support tickets)
- What's the cost of NOT doing it today?
- Is this a must-have or nice-to-have?

Output: High/Medium/Low value with 1-sentence rationale

### Risk Lens
Questions to answer:
- What dependencies exist? (other issues, external services)
- What could block progress? (unclear requirements, missing access)
- What breaks if this goes wrong? (blast radius)
- What's the rollback plan?

Output: High/Medium/Low risk with mitigation strategy

### Effort Lens
Questions to answer:
- Is the stated estimate realistic?
- Any hidden complexity? (integration points, edge cases)
- What's the minimum shippable slice?
- Does this require context from other work?

Output: S(1h)/M(2-4h)/L(4-8h)/XL(8h+) with confidence level

### Security Lens (Conditional)
Apply ONLY when touching: auth, billing, user data, API keys, networking

Questions to answer:
- Does this touch sensitive data?
- Are there compliance implications?
- What's the blast radius if compromised?
- Does this need security review before merge?

Output: Requires review / Safe to proceed

---

## Conflict Handling

When lenses disagree, you MUST:

1. **Name the conflict explicitly**
```
⚠️ CONFLICT: Value (High) vs Risk (High)
   #58 API key encryption is high value but touches security-critical code
```

2. **State what is gained and lost with each choice**
```
   If BUILD: Ship security improvement, but risk of introducing vulnerability
   If DEFER: Safer review process, but delay security hardening
```

3. **Propose resolution options**
```
   Options:
   (a) Build with extra review time (+1h)
   (b) Defer to dedicated security sprint
   (c) Modify: implement read-only first, write later
```

4. **Make a recommendation**
```
   Recommend: (a) Build with extra review - security improvement worth the time
```

### Forbidden Behaviors
- "It depends" without picking a side
- Ignoring opportunity cost
- Optimistic bias without evidence
- Resolving conflicts silently (must be visible)
- Skipping lenses without explicit justification

---

## Decision Outcomes

Every candidate MUST receive one of these outcomes:

| Outcome | Meaning | Required Info |
|---------|---------|---------------|
| **build** | Do it today | Fits time budget, lenses passed |
| **defer** | Not today | Revisit conditions (when/why) |
| **reject** | Won't do | Clear reason (out of scope, duplicate, etc.) |
| **modify** | Change scope | What to cut, what remains |

No decision = incomplete work. Push for resolution.

---

## Maturity-Aware Strictness

Detect project stage from context and adjust:

### Startup / Solo Project
- Favor speed and reversibility
- Allow shipping with known imperfections
- Require: hypothesis and kill criteria for experiments
- Accept: "good enough" over "perfect"

### Scaleup
- Balance speed with stability
- Track technical debt explicitly
- Require: basic test coverage before merge
- Accept: some shortcuts with documented payback plan

### Enterprise
- Favor predictability and safety
- Require full lens coverage on all changes
- Require: comprehensive testing, security review
- Prefer: blocking over warning

**Do NOT change which lenses apply. Only adjust strictness.**

---

## Detailed Execution Flow

### Step 1: Parse Arguments

```
--hours N       (required) Available work hours
--brainstorm    (optional) Use full multi-agent analysis
--no-issues     (optional) Skip GitHub, ask for input
```

### Step 2: Read Yesterday's Context

**Purpose**: Provide continuity from previous day's work and priorities.

**Check for yesterday's wind-down note**:
```bash
# Calculate yesterday's date
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)

# Try Obsidian vault first, fallback to claw daily
if [[ -f "$HOME/Documents/Obsidian/Daily/${YESTERDAY}.md" ]]; then
    DAILY_NOTE="$HOME/Documents/Obsidian/Daily/${YESTERDAY}.md"
elif [[ -f "$HOME/.claw/daily/${YESTERDAY}.md" ]]; then
    DAILY_NOTE="$HOME/.claw/daily/${YESTERDAY}.md"
else
    DAILY_NOTE=""  # No note found - first day or skipped wind-down
fi
```

**Parse relevant sections if note exists**:
```bash
if [[ -n "$DAILY_NOTE" ]]; then
    # Extract Tomorrow's Priorities (becomes "Yesterday's Plans")
    YESTERDAY_PRIORITIES=$(sed -n '/## 🎯 Tomorrow'\''s Priorities/,/^##/p' "$DAILY_NOTE" | grep -v '^##')

    # Extract Focus & Context
    FOCUS_STEALERS=$(grep '**What'\''s stealing focus:**' "$DAILY_NOTE" | sed 's/.*: //')

    # Extract Energy Level
    ENERGY_LEVEL=$(grep '\*\*Energy level:\*\*' "$DAILY_NOTE" | grep -oE '[0-9]+/10')

    # Extract Work Done (to avoid duplication)
    WORK_DONE=$(sed -n '/## 💼 Work Done Today/,/^##/p' "$DAILY_NOTE" | grep -v '^##')
    PERSONAL_DONE=$(sed -n '/## 🎮 Personal Work Done Today/,/^##/p' "$DAILY_NOTE" | grep -v '^##')
fi
```

**Display context to user**:
```markdown
📖 Context from yesterday (YYYY-MM-DD):

**Yesterday you planned to:**
{YESTERDAY_PRIORITIES or "No priorities set"}

**Focus stealers:** {FOCUS_STEALERS or "None noted"}
**Energy level:** {ENERGY_LEVEL or "Not tracked"}

**Work completed yesterday:**
{Summary of WORK_DONE and PERSONAL_DONE}

Want to continue these priorities today, or start fresh?
- Continue yesterday's priorities (add to today's queue)
- Start fresh (plan from scratch)
- Mix (keep some, add new)
```

**Optional: Multi-Day Pattern Analysis**

If `--patterns` flag is set, check last 3-7 days:
```bash
# Analyze last 7 days
for i in {1..7}; do
    DATE=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "${i} days ago" +%Y-%m-%d)
    if [[ -f "$HOME/Documents/Obsidian/Daily/${DATE}.md" ]]; then
        # Extract recurring blockers, energy trends, unfinished priorities
    fi
done

# Show patterns:
# - "Focus stealers appearing 3+ times: Email notifications, Slack"
# - "Average energy: 6.5/10 (trending up)"
# - "Unfinished priorities: Review PR #42 (3 days old)"
```

**Edge Cases**:
- **No note found**: Skip context, proceed normally
- **Multiple missed days**: Offer to check all missed days
- **User declines context**: Proceed normally (don't force)

### Step 3: Gather Candidates

**ultrathink:** Apply comprehensive reasoning to analyze all candidates, evaluate tradeoffs, and create an optimal execution plan.

**Default: Fetch from ALL tracked repos**

If running via `claw`:
```bash
claw issues --label "claude-ready" --json
```

If running via `claude` directly, fetch from each repo:
```bash
# Get current repo
CURRENT_REPO=$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')

# Fetch issues from current repo + any tracked repos
gh issue list --repo "$CURRENT_REPO" --label "claude-ready" --state open \
  --json number,title,labels,body,milestone,repository
```

**Multi-repo aggregation**: When multiple repos are tracked (`claw repos list`),
issues are fetched from ALL repos and grouped by repository in the plan.

**Sort by priority labels**: P1-high > P2-medium > P3-low

**If no issues found OR `--no-issues`:**
```
Ask: "What would you like to accomplish in the next X hours?"
```

### Step 3: Apply Lenses to Each Candidate

For each issue, produce structured analysis:

```markdown
### #53 - Settings doesn't show AI provider

**Value**: HIGH - Blocks user understanding of app state
**Risk**: LOW - Isolated UI change, no backend impact
**Effort**: S (1h) - Clear scope, no dependencies
**Security**: N/A - No sensitive data involved

**Decision**: BUILD
**Rationale**: Quick win, high user impact, low risk
```

### Step 4: Check Time Budget

Sum estimates of BUILD items:
- If under budget: Consider adding more
- If over budget: Force DEFER or MODIFY decisions
- If way over: Ask user to prioritize

### Step 5: Present Plan for Approval

**Multi-Repo Grouping:** When working with a project containing multiple repos,
group issues by repository and show repo type for clarity:

```markdown
## Today's Plan (4 hours available)

### Build (3h total)

#### acme-api (API)
| Order | Issue | Est | Lens Summary |
|-------|-------|-----|--------------|
| 1 | #12 Add rate limiting | 1h | High value, security |
| 2 | #15 Fix auth middleware | 0.5h | High value, unblocks dashboard |

#### acme-dashboard (Web)
| Order | Issue | Est | Lens Summary |
|-------|-------|-----|--------------|
| 3 | #8 Dark mode toggle | 1h | Medium value, UX |
| 4 | #10 Settings page | 0.5h | Low value, depends on api #15 |

#### acme-worker (Service)
(no issues selected for today)

### Cross-Repo Dependencies
- dashboard/#10 depends on api/#15 (auth changes)
- Work order: api first, then dashboard

### Defer
| Repo | Issue | Reason | Revisit |
|------|-------|--------|---------|
| api | #18 API key encryption | 4h exceeds budget | Tomorrow |
| worker | #3 Job retry logic | Needs design review | Next sprint |

### Reject
| Repo | Issue | Reason |
|------|-------|--------|
| dashboard | #6 Slack integration | Needs discussion, not ready |

### Lens Summary
- **Value focus**: Auth improvements blocking production
- **Key risks**: Cross-repo dependency on #15
- **Security**: API auth changes need careful review

### Conflicts Resolved
- api/#12 vs #15: Both high value, chose #15 first (unblocks #10)

### Trade-offs Accepted
- [ ] dashboard/#8 without full design review (trivial change)

---
Approve? (y/n/modify)
```

**Single Repo Mode:** When only one repo is tracked, omit the grouping headers
and show the flat table format.

### Step 6: On Approval

```bash
# Start fresh from main
git checkout main
git pull origin main

# Create branch for FIRST issue only
git checkout -b issue/53-settings-display

# Mark first issue as in-progress
gh issue edit 53 --add-label "in-progress"
```

**Branch Strategy:** Each issue gets its own branch (`issue/<number>-<slug>`).
When `/done` is called, a PR is created and `/next` starts a fresh branch for the next issue.

Create state file: `~/.claw/daily/YYYY-MM-DD.md`

---

## Daily State File Format

```markdown
# Daily Sprint: YYYY-MM-DD

## Config
hours_available: 4
maturity: startup
branch_strategy: pr-per-issue
max_iterations_per_issue: 5
started: 09:00

## Lens Settings
- Value: Prioritize user-facing fixes
- Risk: Accept medium risk for speed
- Security: Flag but don't block

## Plan

### Active
- [ ] #53 - Settings display (~1h)
  - Status: in-progress
  - Branch: issue/53-settings-display
  - Started: 09:15
  - Iteration: 2/5
  - Last error: TypeError: Cannot read property 'theme' of undefined

### Queued
- [ ] #52 - Provider error (~1.5h)
- [ ] #56 - Remove quit button (~0.5h)

### Completed
- [x] #53 - Settings display
  - PR: #15 (https://github.com/owner/repo/pull/15)
  - Completed: 10:30
  - Iterations: 3/5 (passed on 3rd attempt)
  - Iteration log:
    1. Initial implementation → Tests failed (missing validation)
    2. Added validation → Tests failed (edge case)
    3. Fixed edge case → ✅ All tests passing
- [x] #52 - Provider error
  - PR: #16 (https://github.com/owner/repo/pull/16)
  - Completed: 12:15
  - Iterations: 1/5 (first-try success!)

### Blocked
- [ ] #58 - API encryption
  - Status: STUCK (5/5 iterations)
  - Blocker: External API endpoint returning 404
  - Needs human: Verify API configuration in dashboard
  - Iteration log:
    1. Initial implementation → API 404
    2. Updated endpoint → API 404 (same error)
    3. Added auth header → API 404 (same error)
    4. Checked API docs → API 404 (same error - STUCK)
    5. Max iterations → Gave up

### Deferred
- #59 - Performance optimization (low priority, revisit tomorrow)

## PR Merge Order

Track PRs and their merge order/dependencies:

| PR | Issue | Status | Depends On | Merge Order |
|----|-------|--------|------------|-------------|
| #15 | #53 | Open | - | 1 (first) |
| #16 | #52 | Open | - | 2 |
| #17 | #56 | Open | #15 | 3 (after #15 merges) |

**Independent PRs** can merge in any order.
**Dependent PRs** must wait for their dependency to merge first.

## Decisions Made
| Issue | Outcome | Rationale |
|-------|---------|-----------|
| #53 | build | High value, quick win |
| #58 | defer | Exceeds time budget |

## Conflicts Log
- None today

## Session Log
- 09:00 - Planning started
- 09:15 - Plan approved, starting #53
- 10:30 - PR #15 created, starting #52
- 12:15 - PR #16 created, starting #56

## End of Day
(filled by /ship-day)
```

---

## Parallel PR Workflow

With `branch_strategy: pr-per-issue`, each issue gets its own branch and PR.
This enables parallel work without waiting for merges:

### How It Works

1. **Start issue #1** from main: `git checkout -b issue/53-settings-display`
2. **Work on issue #1**, create PR #15
3. **Start issue #2** from main: `git checkout main && git pull && git checkout -b issue/52-provider-error`
4. **Work on issue #2**, create PR #16
5. PRs can be reviewed and merged independently

### Handling Dependencies

When issue #2 depends on issue #1's changes:

**Option A: Wait for merge** (safest)
- Create PR #15 for issue #1
- Wait for review and merge
- Pull main, start issue #2

**Option B: Chain branches** (faster, more complex)
- Create PR #15 for issue #1 (base: main)
- Start issue #2 from issue #1's branch: `git checkout -b issue/52-provider-error issue/53-settings-display`
- Create PR #16 for issue #2 (base: issue/53-settings-display)
- When PR #15 merges, update PR #16's base to main

**Option C: Independent PRs** (if changes are isolated)
- Both PRs target main
- Merge whichever is ready first
- Handle merge conflicts if they arise

### Merge Order Tracking

The daily state file tracks:
- **Which PRs are open** (not yet merged)
- **Dependencies** between PRs
- **Suggested merge order**

Use `/ship-day` to see all open PRs and suggested merge order.

---

## Integration with Other Commands

| Command | When to Use |
|---------|-------------|
| `/brainstorm` | Full multi-agent deep analysis |
| `/next` | Move to next queued issue |
| `/done` | Mark current issue complete, update state |
| `/pivot` | Mid-day replan (preserves context) |
| `/summary` | Review all completed work before shipping |
| `/validate` | Run QA checks before shipping |
| `/ship-day` | End of day summary and commit |

---

## Anti-Patterns (Forbidden)

During planning, NEVER:
- Give generic advice without specifics
- Show feature enthusiasm without opportunity cost
- Over-explain without deciding
- Say "we should consider..." without resolution
- Skip a lens without stating why
- Resolve lens conflicts silently
- Leave any candidate without a decision outcome
