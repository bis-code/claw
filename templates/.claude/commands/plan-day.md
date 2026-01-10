---
description: Plan the day's work based on available hours using lens-based analysis (alias for /auto --plan-only)
args: --hours <number> [--brainstorm] [--no-issues]
---

# /plan-day --hours X

> **Note:** `/plan-day` is now an alias for `/auto --plan-only`. For full autonomous execution, use `/auto` instead.

Plan today's work using time-boxed, lens-enforced decision making.

## Usage

### Direct (Legacy)
```bash
/plan-day --hours 4              # Plan for 4 hours of work
/plan-day --hours 6 --brainstorm # Full multi-agent analysis
/plan-day --hours 2 --no-issues  # Skip GitHub, ask what to work on
```

### Via /auto (Recommended)
```bash
/auto --plan-only                # Uses default 4 hours
/auto --plan-only --hours 6      # Custom time budget
/auto --plan-only --focus "billing"  # Focus on specific area
```

## Options

- `--hours <number>` - Time budget in hours (required)
- `--brainstorm` - Enable multi-agent analysis with CTO, Product, UX, QA perspectives
- `--no-issues` - Skip GitHub issue fetching, ask user what to work on

## Execution

### Step 0: Initialize Project Index (Auto)

Before planning, check if project index exists:

```bash
# Check for index
if [ ! -f ".claude/project-index.json" ]; then
    echo "No project index found. Generating..."
    # Trigger /index command
fi
```

**Actions:**
1. If `.claude/project-index.json` doesn't exist → Generate it (mono or multi-repo)
2. If index exists but is stale (`stale: true`) → Offer to update
3. If index exists and fresh → Continue to planning

This ensures efficient searching throughout the work session.

### Step 1: Gather Candidates

**Default**: Fetch GitHub issues labeled `claude-ready` from all tracked repos
```bash
# If claw is available (multi-repo support)
claw issues --label claude-ready

# Fallback to single repo
gh issue list --label "claude-ready" --state open --json number,title,labels,body
```

**Multi-repo**: If you have repos tracked with `claw repos add`, issues are fetched from:
1. Current directory's repo (from git remote)
2. All tracked repos

**Fallback**: If no issues or `--no-issues` flag:
> "What would you like to accomplish in the next X hours?"

### Step 2: Apply Decision Lenses (Mandatory)

For each candidate, apply these lenses explicitly:

#### Value Lens
- Who benefits? What metric moves?
- What's the cost of NOT doing this today?
- Is this a must-have or nice-to-have?

#### Risk Lens
- What dependencies exist?
- What could block progress?
- What breaks if this goes wrong?

#### Effort Lens
- Is the estimate realistic?
- Hidden complexity?
- What's the minimum shippable slice?

#### Security Lens (when touching auth/data/billing)
- Does this touch sensitive data?
- Are there compliance implications?
- What's the blast radius if compromised?

### Step 3: Surface Conflicts

If lenses disagree, state explicitly:
```
⚠️ CONFLICT: Value says ship #42 now, Risk says auth changes need review
   → Options: (a) ship with extra testing, (b) defer to tomorrow, (c) split scope
```

**Forbidden behaviors:**
- "It depends" without resolution
- Ignoring opportunity cost
- Optimistic bias without evidence
- Resolving conflicts silently

### Step 4: Decide for Each Issue

Each issue MUST get one outcome:
- **build** - Do it today, fits time budget
- **defer** - Not today, state revisit conditions
- **reject** - Won't do, explain why
- **modify** - Split or reduce scope to fit

### Step 5: Present Plan

```markdown
## Today's Plan (X hours available)

### Build (Y hours total)
| # | Issue | Est | Decision Rationale |
|---|-------|-----|-------------------|
| 1 | #53 Settings bug | 1h | Quick win, unblocks #52 |
| 2 | #52 Provider error | 1.5h | High value, clear scope |

### Defer
- #58 API key encryption (4h) - Exceeds budget, revisit tomorrow

### Reject
- #47 Already in-progress by someone else

### Lens Analysis Summary
**Value**: #53 + #52 fix critical UX issues blocking adoption
**Risk**: Both touch settings - test thoroughly
**Effort**: Estimates accurate, no hidden complexity

### Conflicts Resolved
- #58 vs #53: Chose #53 (quick win) over #58 (important but large)

### Trade-offs Accepted
- [ ] Shipping before full E2E coverage (acceptable for beta)
```

### Step 6: On Approval

```bash
git checkout -b daily/$(date +%Y-%m-%d)
gh issue edit <first-issue> --add-label "in-progress"
```

Create `.claude/daily/YYYY-MM-DD.md` with the approved plan.

## Maturity Awareness

Adjust strictness based on project stage:

| Stage | Behavior |
|-------|----------|
| **Startup** | Favor speed, allow imperfection, require kill criteria |
| **Scaleup** | Balance speed/stability, track debt explicitly |
| **Enterprise** | Favor safety, require full lens coverage, prefer blocking |

## Anti-Patterns (Forbidden)

- Generic advice without specifics
- Feature enthusiasm without opportunity cost
- Over-explaining without deciding
- Vague "we should consider..." without resolution
- Skipping lenses without explicit justification
