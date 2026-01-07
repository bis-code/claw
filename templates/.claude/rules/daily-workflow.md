# Daily Workflow Rules

This rule file governs the autonomous daily development workflow.

## Branch Naming (PR-per-Issue)
- Issue branches: `issue/<number>-<short-slug>`
- Examples: `issue/42-payment-modal`, `issue/53-settings-display`
- Never push directly to main
- Each issue gets its own branch and PR
- Fresh branch from main for each issue

## Commits (PR-per-Issue)
- Use conventional format: `<type>(<scope>): <description>`
- Reference issue: `Closes #123` in commit body
- Each issue gets clean commits since each has its own PR
- Tests must pass before committing

## PR Requirements
- One PR per issue (not batched)
- PR title matches commit message format
- PR body includes test plan and links to issue
- CI must pass before merge

## Pivot Protocol
- Always log pivots in the daily file with timestamp
- Update GitHub labels when issue status changes
- Deferred issues get a comment explaining why
- Pivots are first-class citizens, not failures

## AI Restructuring
- Claude should proactively suggest groupings when patterns emerge
- Suggestions are logged in the daily file (even if rejected)
- Accepted patterns become templates for future days

## Multi-Perspective Analysis

Claude should offer insights from multiple roles when relevant:

| Role | Focus | Example Insight |
|------|-------|-----------------|
| **Product Owner** | Value, user impact, priorities | "This directly impacts conversion rate" |
| **UX** | Usability, accessibility, user experience | "Users struggle here - consider usability testing" |
| **CTO** | Architecture, tech debt, scalability | "This adds coupling - consider abstraction" |
| **Sales** | Customer requests, competitive advantage | "Three enterprise customers asked for this" |
| **Marketing** | Positioning, launches, messaging | "This is blog-worthy - coordinate announcement" |
| **CEO** | Strategic alignment, ROI, OKRs | "Aligns with Q1 retention goal" |
| **Scrum Master** | Process, blockers, velocity | "This blocks #45 and #46 - prioritize" |

### When to Offer Perspectives
- During `/plan-day`: Suggest order based on business value
- During `/pivot`: Consider business impact of changes
- When issues have `perspectives` tags: Address those specifically
- Opportunistically: When Claude spots business implications

## Daily File Format

See `.claude/skills/daily-workflow/plan-day.md` for the canonical format.

Key sections:
- **Status**: Current state of the day
- **Issues**: Active, Completed, Deferred
- **Pivots**: Changes made with reasons
- **Perspectives**: Role-based insights offered
- **AI Notes**: Patterns spotted, suggestions made
