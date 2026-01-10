# /brainstorm

Multi-agent collaborative planning session.

## What This Skill Does

Spawns multiple specialized agents in parallel to analyze today's issues, then runs a debate round where agents respond to each other. The result is a synthesized plan with diverse perspectives and automatically created follow-up issues.

## Invocation

```
/brainstorm
```

Or with specific agents:

```
/brainstorm --agents "senior-dev,product,cto"
```

---

## Agent Roster

| Agent | Role | Focus | Typical Output |
|-------|------|-------|----------------|
| **Senior Developer** | Technical implementer | Code quality, patterns, approach | "I'd implement #42 using X pattern" |
| **Product Owner** | Value guardian | ROI, user impact, priorities | "Value order: #38 > #42 > #45" |
| **CTO/Architect** | System thinker | Tech debt, scalability, risk | "Watch for coupling in #47" |
| **QA Engineer** | Quality guardian | Test coverage, edge cases | "Need E2E for auth changes" |
| **UX Designer** | User advocate | Usability, accessibility | "User flow in #42 needs work" |

---

## Execution Flow

### Phase 1: Parallel Analysis (5 agents simultaneously)

```
┌─────────────────────────────────────────────────────────────────┐
│  Spawn agents in parallel via Task tool                         │
│                                                                  │
│  Each agent receives:                                           │
│  - All issues labeled 'claude-ready'                            │
│  - Their role description and focus areas                       │
│  - Instruction to output structured analysis                    │
│                                                                  │
│  Senior Dev ──┐                                                 │
│  Product     ─┼──▶ [Parallel execution]                        │
│  CTO         ─┤                                                 │
│  QA          ─┤                                                 │
│  UX          ─┘                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Phase 2: Debate Round (Sequential)

```
┌─────────────────────────────────────────────────────────────────┐
│  Each agent sees all other agents' outputs                      │
│                                                                  │
│  Senior Dev: "I see CTO flagged tech debt in #47.              │
│               I agree - let me propose a cleaner approach..."   │
│                                                                  │
│  Product: "Senior Dev wants more time on #47, but              │
│            value says ship fast. Can we compromise?"            │
│                                                                  │
│  CTO: "Compromise: Ship #47 today, I'll create a               │
│         tech debt ticket #51 for the refactor."                │
└─────────────────────────────────────────────────────────────────┘
```

### Phase 3: Synthesis

```
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator synthesizes all inputs:                           │
│                                                                  │
│  Final Plan for Today:                                          │
│  1. #38 - Warm-up (all agree)                                  │
│  2. #42 - Main work (Senior Dev approach accepted)             │
│  3. #47 - Ship fast (Product + CTO compromise)                 │
│                                                                  │
│  Auto-Created Issues:                                           │
│  - #51: Tech debt from #47 (created by CTO agent)              │
│  - #52: Usability review for #42 (created by UX agent)         │
│                                                                  │
│  Debate Insights:                                               │
│  - Senior Dev vs CTO on #47 → Resolved via tech debt ticket   │
│  - QA flagged missing E2E → Added to acceptance criteria       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Agent Prompts

### Senior Developer Agent

```markdown
ultrathink: You are a Senior Developer analyzing issues for today's sprint.

Your focus:
- Code quality and maintainability
- Implementation approach and patterns
- Technical feasibility and effort estimation
- Opportunities to improve existing code

For each issue, provide:
1. Your recommended implementation approach
2. Potential pitfalls or challenges
3. Suggestions for code improvements
4. Effort estimate (agree/disagree with stated scope)

Be opinionated. If you see a better way, say so.
Express disagreements constructively.
```

### Product Owner Agent

```markdown
ultrathink: You are a Product Owner analyzing issues for today's sprint.

Your focus:
- User value and business impact
- Priority ordering based on ROI
- Acceptance criteria completeness
- Dependencies that affect delivery

For each issue, provide:
1. Value assessment (High/Medium/Low with reasoning)
2. Suggested priority order for today
3. Any acceptance criteria gaps
4. Risk to users if delayed

Think about: What moves the needle most for users today?
```

### CTO/Architect Agent

```markdown
ultrathink: You are a CTO/Architect analyzing issues for today's sprint.

Your focus:
- System architecture and design
- Technical debt identification
- Scalability and performance implications
- Cross-service dependencies

For each issue, provide:
1. Architectural concerns or approvals
2. Technical debt this might introduce
3. Dependencies on other systems/issues
4. Suggestions for tech debt tickets to create

You can CREATE new issues for tech debt you identify.
Use: gh issue create --title "Tech Debt: X" --label "tech-debt"
```

### QA Engineer Agent

```markdown
ultrathink: You are a QA Engineer analyzing issues for today's sprint.

Your focus:
- Test coverage requirements
- Edge cases and error scenarios
- Regression risk assessment
- Test strategy validation

For each issue, provide:
1. Required test types (Unit/Integration/E2E)
2. Critical edge cases to cover
3. Regression risks
4. Missing test scenarios in acceptance criteria

If test strategy seems insufficient, flag it strongly.
```

### UX Designer Agent

```markdown
ultrathink: You are a UX Designer analyzing issues for today's sprint.

Your focus:
- User experience and flow
- Accessibility requirements
- Usability concerns
- UI consistency

For each issue, provide:
1. UX implications and concerns
2. Accessibility requirements (if applicable)
3. User flow considerations
4. Suggestions for UX improvements

You can CREATE issues for UX improvements you identify.
Use: gh issue create --title "UX: X" --label "ux-improvement"
```

---

## Implementation

### Step 1: Fetch Issues (Multi-Repo)

**Fetch from ALL tracked repos:**

If running via `claw`:
```bash
claw issues --label "claude-ready" --json > /tmp/brainstorm-issues.json
```

If running via `claude` directly:
```bash
# Current repo
CURRENT_REPO=$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
gh issue list --repo "$CURRENT_REPO" --label "claude-ready" --state open \
  --json number,title,body,labels,repository \
  > /tmp/brainstorm-issues.json
```

**Multi-repo context:** When issues come from multiple repos, agents analyze
cross-repo dependencies and provide context-aware recommendations. Issues are
presented grouped by repository so agents understand the broader project context.

### Step 2: Spawn Parallel Agents

Using Claude Code's Task tool, spawn 5 agents simultaneously:

```
Task(subagent_type="general-purpose", prompt="[Senior Dev prompt + issues]")
Task(subagent_type="general-purpose", prompt="[Product prompt + issues]")
Task(subagent_type="general-purpose", prompt="[CTO prompt + issues]")
Task(subagent_type="general-purpose", prompt="[QA prompt + issues]")
Task(subagent_type="general-purpose", prompt="[UX prompt + issues]")
```

### Step 3: Collect & Share Outputs

Wait for all agents, then spawn debate round:

```
Task(subagent_type="general-purpose", prompt="
  You are Senior Dev. Here's what all agents said:
  [All outputs]

  Respond to any disagreements or build on others' ideas.
  You may revise your recommendations.
")
```

### Step 4: Synthesize

Final orchestrator pass:

```
Task(subagent_type="general-purpose", prompt="
  You are the Orchestrator. Synthesize these agent outputs:
  [All outputs + debate responses]

  Create the final plan:
  - Ordered list of issues for today
  - Resolution of any disagreements
  - List of auto-created issues
  - Key insights from the debate
")
```

### Step 5: Create Auto Issues

Agents with issue creation permission (CTO, UX) can run:

```bash
gh issue create \
  --title "Tech Debt: Refactor payment module coupling" \
  --label "tech-debt,claude-ready" \
  --body "Created by CTO agent during brainstorm.

  Context: While reviewing #47, identified coupling issue.

  Suggested approach: Extract payment interface.

  Priority: P2 (after current sprint)"
```

---

## Output Format

After brainstorming, create/update the daily file with:

```markdown
# Daily Sprint: YYYY-MM-DD

## Brainstorm Results

### Agent Consensus
- All agents agree: #38 first (warm-up, low risk)
- Majority: #42 second (high value, Senior Dev approach)

### Debate Highlights
- **Senior Dev vs CTO on #47**:
  - Senior Dev: "Needs proper abstraction"
  - CTO: "Ship fast, refactor later"
  - Resolution: Ship today, tech debt ticket created (#51)

- **QA flagged #42**:
  - Missing E2E test scenario for 3D Secure
  - Added to acceptance criteria

### Auto-Created Issues
- #51: Tech Debt - Payment module coupling (CTO)
- #52: UX Review - Checkout flow clarity (UX)

### Final Plan
1. #38 - Fix checkout errors (warm-up)
2. #42 - Payment modal (main work, Senior Dev approach)
3. #47 - Ship fast (with tech debt ticket)

## Agent Perspectives

### Senior Developer
[Full analysis]

### Product Owner
[Full analysis]

### CTO/Architect
[Full analysis]

### QA Engineer
[Full analysis]

### UX Designer
[Full analysis]
```

---

## Integration with /plan-day

`/brainstorm` can be invoked automatically by `/plan-day` or run standalone:

```
/plan-day                    # Basic planning (single agent)
/plan-day --brainstorm       # Full multi-agent brainstorm
/brainstorm                  # Just brainstorm, don't create branch
```
