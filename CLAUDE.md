# CLAUDE.md — Claw Project

> **Project:** Claw - Claude Automated Workflow CLI
> **Type:** Open-source developer tool

---

## Project Overview

**Claw v3** is a minimal bootstrapper that installs Claude Code skills for autonomous development.

**What it does:**
- `npx claw init` → sets up skills in `.claude/skills/`
- Everything else is Claude Code skills: `/run`, `/bug`, `/feature`, `/improvement`
- No separate CLI - Claude Code handles all interaction

**Key Concepts:**
- Solo mode: Obsidian only (stealth)
- Team mode: GitHub + Obsidian synced
- Session file (`.claw-session.md`) survives context compaction

---

## Active Session

**CRITICAL: On EVERY session start (including after context compaction):**

1. **Read the session overview:**
   ```
   mcp__obsidian__read_note("Projects/claw/2026-02-01-v3-implementation/_overview.md")
   ```

2. **Find current progress:**
   - Look at "Live Progress Tracker" section
   - Find "**Current Task:**" line
   - Check task status in epic tables

3. **Resume from checkpoint:**
   - Continue from the current task
   - DO NOT restart from the beginning
   - DO NOT re-analyze completed work

4. **Acknowledge:**
   ```
   Session: v3 Implementation
   Current: [Epic X, Task Y]
   Next: [Specific action]
   ```

---

## Repository Structure (v3)

```
claw/
├── src/
│   └── init/               # npx claw init command
│       └── index.ts
├── templates/
│   ├── skills/             # Skill templates to copy
│   │   ├── run.md
│   │   ├── bug.md
│   │   ├── feature.md
│   │   └── improvement.md
│   └── config.json         # Default config template
├── tests/                  # Jest tests
└── CLAUDE.md               # This file
```

---

## Development Commands

```bash
npm install                 # Install dependencies
npm run build               # Build TypeScript
npm test                    # Run tests
npm run dev                 # Development mode

# Test locally
npx . init                  # Test init in current dir
```

---

## Critical Rules

### TDD is Mandatory
- Write tests before implementation
- Tests must pass before committing

### Git Workflow
- Branch from develop: `feature/v2-<description>`
- Conventional commits: `feat(cli):`, `fix(core):`, etc.
- PR to develop, then develop to main for releases

### After Each Task
1. Update Obsidian progress tracker:
   ```
   mcp__obsidian__patch_note(
     path="Projects/claw/2026-02-01-v3-implementation/_overview.md",
     oldString="| 1.1 | ⏳ |",
     newString="| 1.1 | ✅ |"
   )
   ```
2. Update "Live Progress Tracker" counts
3. Update "**Current Task:**" to next task
4. Add entry to "Session Log"

---

## Related Documentation

All in Obsidian at `Projects/claw/`:
- `design-2026-02-01-claw-v3-simplification.md` - v3 Design (current)
- `2026-02-01-v3-implementation/_overview.md` - Active session tracker
- `research-2026-01-31-market-analysis.md` - Market research
- `problem-statement-2026-01-31.md` - Engineering problem statement

---

*Claw project — building the orchestration layer for autonomous AI development*
