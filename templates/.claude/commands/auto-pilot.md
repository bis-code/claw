---
description: Full autonomous mode - discover work, plan, execute, and ship (project)
---

# Auto-Pilot - Full Autonomous Development

Run a complete autonomous development cycle with a **4-hour default time budget**.

> **Default behavior:** Claude will work autonomously for up to 4 hours, then ship and report.

## Phase 1: Discovery

Launch discovery agents in parallel to find work:

1. **TODO Scanner**: `grep -rn "TODO\|FIXME\|HACK" --include="*.go" --include="*.ts"`
2. **Test Coverage Agent**: Find files without tests, missing E2E flows
3. **Code Quality Agent**: Long functions, duplication, inconsistent patterns
4. **Security Agent**: Hardcoded secrets, injection risks, missing auth
5. **Dependency Agent**: `npm outdated`, `go list -m -u all`

Each agent creates GitHub issues for significant findings.

## Phase 2: Aggregate & Prioritize

Combine existing `claude-ready` issues with discovered issues.
Deduplicate and prioritize:
- Security → P0
- Test gaps on critical paths → P1
- Tech debt in active areas → P2
- TODOs → P3

## Phase 3: Brainstorm

Run `/brainstorm` with all issues for multi-agent planning.

## Phase 4: Execute (Autonomous)

Uses the autonomous executor for TDD-driven implementation:

```bash
# Initialize and import prioritized issues
/autonomous --init
/autonomous --import --label "in-progress"

# Run with feedback loops and blocker handling
/autonomous --run --loop
```

The executor:
1. Creates checkpoint before each task
2. Runs tests first (TDD)
3. Parses errors and suggests fixes
4. Auto-resolves blockers (missing deps, rate limits)
5. Requests human help for fatal blockers (permissions, auth)
6. Commits on success, logs failure on error

## Phase 5: Ship

Run `/ship-day` to squash, create PR, close issues.

## Options
- `--hours N`: Time budget in hours (default: **4 hours**)
- `--focus "area"`: Focus on specific area (optional)
- `--discovery [deep|shallow|none]`: Discovery depth (default: shallow)
- `--discover-only`: Just discover, don't execute

## Safety Rails
- Pause for human input on security-critical changes
- Create backup tag before execution
- Max 10 issues created, 20 commits per session

Reference `.claude/skills/daily-workflow/auto-pilot.md` for full details.

## Autonomous Modules

The execution engine is powered by:

| Module | Location | Purpose |
|--------|----------|---------|
| executor.sh | `lib/autonomous/` | Task queue, execution loop |
| feedback.sh | `lib/autonomous/` | Test runner, error parsing |
| blocker.sh | `lib/autonomous/` | Blocker detection, resolution |
| checkpoint.sh | `lib/autonomous/` | State persistence, rollback |

See `/autonomous --help` for standalone usage.
