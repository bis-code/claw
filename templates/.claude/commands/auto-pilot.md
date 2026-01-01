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

## Phase 4: Execute

Senior Developer agent implements each issue:
1. Read issue, analyze context
2. Write tests first (TDD)
3. Implement solution
4. QA agent validates
5. Commit and move to next

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
