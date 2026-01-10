---
description: One command to rule them all - discover, plan, execute, and ship (or just plan)
---

# /auto - Unified Autonomous Development

**One command to rule them all.** Run a complete autonomous cycle or just plan - you choose.

> **Default behavior:** Claude will work autonomously for up to 4 hours, then ship and report.

## Quick Start

```bash
/auto                           # Full cycle: discover → plan → execute → ship (4 hours)
/auto --plan-only               # Just discover and plan, then stop
/auto --skip-discovery          # Skip discovery, plan and execute existing issues only
```

## What It Does

### Full Mode (Default)

1. **Discovery**: Launch agents to find work (TODOs, test gaps, security issues)
2. **Context Reading**: Parse yesterday's wind-down notes for continuity
3. **Aggregation**: Combine discovered + existing issues, deduplicate
4. **Brainstorming**: Multi-agent planning with 5 perspectives
5. **Execution**: TDD-driven implementation with autonomous error handling
6. **Shipping**: Squash commits, create PR, close issues
7. **Reporting**: Full summary of discovered + completed work

### Plan-Only Mode (`--plan-only`)

1. **Discovery**: Launch agents to find work
2. **Context Reading**: Parse yesterday's notes
3. **Aggregation**: Combine and deduplicate issues
4. **Brainstorming**: Multi-agent planning
5. **Output**: Prioritized plan for manual review
6. **Stop**: No execution, no commits

> **Tip:** Use `/plan-day` as a shortcut for `/auto --plan-only`

## Options

| Flag | Description | Example |
|------|-------------|---------|
| `--plan-only` | Stop after planning, don't execute | `/auto --plan-only` |
| `--skip-discovery` | Use existing issues only | `/auto --skip-discovery` |
| `--hours N` | Time budget (default: 4) | `/auto --hours 8` |
| `--focus "area"` | Focus on specific area | `/auto --focus "billing"` |
| `--discovery [deep\|shallow\|none]` | Discovery depth | `/auto --discovery deep` |

## Discovery Agents

When discovery is enabled (default), these agents run in parallel:

1. **TODO Scanner**: `grep -rn "TODO\|FIXME\|HACK"` - finds deferred work
2. **Test Coverage Agent**: Files without tests, missing E2E flows
3. **Code Quality Agent**: Long functions, duplication, inconsistent patterns
4. **Security Agent**: Hardcoded secrets, injection risks, missing auth checks
5. **Dependency Agent**: `npm outdated`, `go list -m -u all` - outdated deps

Each agent creates GitHub issues with `claude-ready` label for significant findings.

## Context Reading

Reads yesterday's wind-down notes from:
- `~/Documents/Obsidian/Daily/YYYY-MM-DD.md` (if Obsidian configured)
- `~/.claw/daily/YYYY-MM-DD.md` (fallback)

Extracts:
- Yesterday's unfinished priorities → elevated to P1
- Recurring blockers → flagged in discovery report
- Energy trends → influence time budget allocation

## Safety Rails

- Pause for human input on security-critical changes (auth, payments, migrations)
- Create backup tag before execution: `git tag auto-start-YYYYMMDD-HHMM`
- Max 10 issues created per session
- Max 20 commits per day
- Pause after 5 issues completed for review

## Command Relationships

```
/auto                         # Main command (full cycle)
  ├─> /auto --plan-only       # Planning only
  │     └─> /plan-day (alias) # Legacy alias
  └─> Internal skills:
      ├─> /brainstorm         # Multi-agent planning
      └─> /autonomous         # Execution loop
```

**Recommendation:** Use `/auto` for everything. It's intelligent by default.

## Implementation Details

Reference `.claude/skills/daily-workflow/auto.md` for full specification.

Execution engine powered by:

| Module | Location | Purpose |
|--------|----------|---------|
| executor.sh | `lib/autonomous/` | Task queue, execution loop |
| feedback.sh | `lib/autonomous/` | Test runner, error parsing |
| blocker.sh | `lib/autonomous/` | Blocker detection, resolution |
| checkpoint.sh | `lib/autonomous/` | State persistence, rollback |
