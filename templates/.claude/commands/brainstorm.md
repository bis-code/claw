---
description: Multi-agent collaborative planning with parallel analysis and debate (internal - called by /auto)
---

# Multi-Agent Brainstorm

> **Note:** This is an internal command called by `/auto`. For everyday use, run `/auto` or `/auto --plan-only` instead.

Spawn multiple specialized agents to analyze today's issues collaboratively.

## Phase 1: Parallel Analysis

Launch these agents simultaneously using Task tool:

1. **Senior Developer Agent**: Implementation approach, code quality, patterns
2. **Product Owner Agent**: Value assessment, priority ordering, ROI
3. **CTO/Architect Agent**: Tech debt, scalability, architecture concerns
4. **QA Engineer Agent**: Test coverage, edge cases, regression risks
5. **UX Designer Agent**: Usability, accessibility, user flow

Each agent analyzes all `claude-ready` issues and provides structured output.

## Phase 2: Debate Round

Share all agent outputs, then each agent responds to others:
- Senior Dev may agree with CTO on tech debt
- Product may counter with "ship fast" argument
- Resolution emerges through debate

## Phase 3: Synthesis

Create final plan:
- Ordered list of issues for today
- Resolution of any disagreements
- Auto-created issues (tech debt, UX improvements)
- Key insights from debate

## Auto Issue Creation

CTO and UX agents can create issues:
```bash
gh issue create --title "[Auto] Tech Debt: X" --label "tech-debt,claude-ready"
```

Reference `.claude/skills/daily-workflow/brainstorm.md` for full agent prompts and details.
