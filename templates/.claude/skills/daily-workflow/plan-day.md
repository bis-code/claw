# /plan-day

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

```
/plan-day --hours 4              # Plan for 4 hours
/plan-day --hours 6 --brainstorm # Full multi-agent analysis
/plan-day --hours 2 --no-issues  # Manual input mode
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

### Step 2: Gather Candidates

**Default: Fetch from GitHub**
```bash
gh issue list --label "claude-ready" --state open \
  --json number,title,labels,body,milestone
```

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

```markdown
## Today's Plan (4 hours available)

### Build (3h total)
| Order | Issue | Est | Lens Summary |
|-------|-------|-----|--------------|
| 1 | #53 Settings display | 1h | High value, low risk |
| 2 | #52 Provider error | 1.5h | High value, low risk |
| 3 | #56 Remove quit button | 0.5h | Low value, no risk (filler) |

### Defer
| Issue | Reason | Revisit |
|-------|--------|---------|
| #58 API encryption | 4h exceeds budget | Tomorrow with full focus |
| #47 License sync | Already in-progress | Check status first |

### Reject
| Issue | Reason |
|-------|--------|
| #36 Discord bot | Needs discussion, not ready |

### Lens Summary
- **Value focus**: UX improvements blocking adoption
- **Key risks**: None significant today
- **Security**: No sensitive changes in today's batch

### Conflicts Resolved
- #52 vs #53: Both high value, chose #53 first (unblocks #52)

### Trade-offs Accepted
- [ ] Shipping #56 without full design review (trivial change)

---
Approve? (y/n/modify)
```

### Step 6: On Approval

```bash
# Create daily branch
git checkout -b daily/$(date +%Y-%m-%d)

# Mark first issue
gh issue edit 53 --add-label "in-progress"
```

Create state file: `.claude/daily/YYYY-MM-DD.md`

---

## Daily State File Format

```markdown
# Daily Sprint: YYYY-MM-DD

## Config
hours_available: 4
maturity: startup
branch: daily/YYYY-MM-DD
started: 09:00

## Lens Settings
- Value: Prioritize user-facing fixes
- Risk: Accept medium risk for speed
- Security: Flag but don't block

## Plan

### Active
- [ ] #53 - Settings display (~1h)
  - Status: in-progress
  - Started: 09:15

### Queued
- [ ] #52 - Provider error (~1.5h)
- [ ] #56 - Remove quit button (~0.5h)

### Completed
(moves here when done)

### Deferred
- #58 - API encryption (revisit tomorrow)

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

## End of Day
(filled by /ship-day)
```

---

## Integration with Other Commands

| Command | When to Use |
|---------|-------------|
| `/brainstorm` | Full multi-agent deep analysis |
| `/next` | Move to next queued issue |
| `/done` | Mark current issue complete, update state |
| `/pivot` | Mid-day replan (preserves context) |
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
