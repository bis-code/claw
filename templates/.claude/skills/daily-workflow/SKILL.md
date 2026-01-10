# Daily Workflow System

Autonomous daily development workflow with multi-agent AI collaboration.

## Commands

| Command | Purpose | Autonomy Level |
|---------|---------|----------------|
| `/plan-day` | Start the day - fetch issues, analyze, create branch | Basic |
| `/brainstorm` | Multi-agent collaborative planning session | Multi-Agent |
| `/auto` | Full autonomous: discover, plan, execute, ship | Full Autonomy |
| `/next` | Pick up the next issue from today's plan | Manual |
| `/done` | Mark current issue as complete | Manual |
| `/pivot` | Handle mid-day changes (blocker, idea, scope, urgent) | Manual |
| `/summary` | Show all completed work today (for verification) | Manual |
| `/ship-day` | End the day - squash commits, create PR | Manual |

## Autonomy Levels

```
Manual           Multi-Agent           Full Autonomy
──────           ───────────           ─────────────
/plan-day        /brainstorm           /auto
/next            /plan-day              │
/done             --brainstorm          ├── Discovery
/pivot                                  ├── Brainstorm
/ship-day                               ├── Execute
                                        └── Ship
```

## Agent Roster

| Agent | Role | Focus |
|-------|------|-------|
| **Senior Developer** | Implementer | Code quality, patterns, opinions |
| **Product Owner** | Value guardian | ROI, priorities, user impact |
| **CTO/Architect** | System thinker | Tech debt, scalability |
| **QA Engineer** | Quality guardian | Test coverage, edge cases |
| **UX Designer** | User advocate | Usability, accessibility |
| **Discovery Agents** | Work finders | TODOs, coverage gaps, security |

## State

Daily state is stored in `.claude/daily/YYYY-MM-DD.md`

## Workflow Modes

### Manual Mode
```
/plan-day ──▶ /next ──▶ work ──▶ /done ──▶ /summary ──▶ /ship-day
                │         │                    │
                └─ /pivot ┘                    └── verify completed
```

### Multi-Agent Mode
```
/brainstorm ──▶ /plan-day ──▶ /next ──▶ work ──▶ /done ──▶ /ship-day
     │
     └── Parallel agents debate and plan
```

### Full Autonomous Mode
```
/auto
     │
     ├── 1. Discovery (find work in codebase)
     ├── 2. Create issues (auto-labeled)
     ├── 3. Brainstorm (multi-agent)
     ├── 4. Execute (Senior Dev + QA validate)
     └── 5. Ship (PR + close issues)
```

## Discovery Sources (Auto-Pilot)

| Source | What It Finds |
|--------|---------------|
| TODO Scanner | Unfinished work, FIXMEs, HACKs |
| Test Coverage | Untested code, missing E2E |
| Code Quality | Long functions, duplication |
| Security Scan | Vulnerabilities, hardcoded secrets |
| Dependency Check | Outdated packages |

## Multi-Perspective Analysis

Agents offer insights from business roles:
- **Product Owner**: Value and priorities
- **UX**: Usability and accessibility
- **CTO**: Architecture and tech debt
- **Sales**: Customer impact
- **Marketing**: Positioning and launches
- **CEO**: Strategic alignment
- **Senior Developer**: Implementation opinions
