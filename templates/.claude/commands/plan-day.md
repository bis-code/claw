---
description: Plan the day's work based on available hours using lens-based analysis
args: --hours <number> [--brainstorm] [--no-issues]
---

# /plan-day --hours X

Plan today's work using time-boxed, lens-enforced decision making.

## Usage

```
/plan-day --hours 4              # Plan for 4 hours of work
/plan-day --hours 6 --brainstorm # Full multi-agent analysis
/plan-day --hours 2 --no-issues  # Skip GitHub, ask what to work on
```

## Execution

### Step 1: Gather Candidates

**Default**: Fetch GitHub issues labeled `claude-ready`
```bash
gh issue list --label "claude-ready" --state open --json number,title,labels,body
```

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
