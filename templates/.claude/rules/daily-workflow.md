# Daily Workflow Rules

This rule file governs the autonomous daily development workflow.

## Branch Naming
- Daily branches: `daily/YYYY-MM-DD`
- Never push directly to main
- All work for a day goes on a single branch

## During-Day Commits
- Can be messy: "wip", "trying x", "fix"
- Will be squashed at end of day
- Each commit should still run tests (but doesn't need perfect messages)

## Ship-Time Commits
- Must follow conventional format: `<type>(<scope>): <description>`
- Must reference issue numbers: `(#123)` or `Closes #123`
- Must pass all hooks (test coverage validation)

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
