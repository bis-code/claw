# CLAUDE.md — Claw Project

> **Project:** Claw - Claude Automated Workflow CLI
> **Type:** Open-source developer tool

---

## Project Overview

**Claw** is a standalone CLI tool that orchestrates autonomous AI development. It manages features across mono/multi-repos, maintains context in Obsidian, and spawns Claude Code sessions as workers.

**Key Differentiators:**
- Document-driven (Obsidian as brain)
- Decision checkpoints (AI pauses for approval)
- Pivot-friendly (expects changes)
- Collaborative loop (AI discovers → Engineer decides → AI executes → Engineer pivots)

---

## Active Session

**CRITICAL: On EVERY session start (including after context compaction):**

1. **Read the session overview:**
   ```
   mcp__obsidian__read_note("Projects/claw/2026-01-31-v2-orchestration-tool/_overview.md")
   ```

2. **Find current progress:**
   - Look at "Live Progress Tracker" section
   - Find the epic/story that is "🔄 In Progress"
   - Check "**Current Task:**" line

3. **Resume from checkpoint:**
   - Continue from the current task
   - DO NOT restart from the beginning
   - DO NOT re-analyze completed work

4. **Acknowledge:**
   ```
   📂 Session: Projects/claw/2026-01-31-v2-orchestration-tool/
   📊 Current: [Epic X, Story Y]
   🎯 Next: [Specific action]
   ```

---

## Repository Structure

```
claw/
├── bin/                    # CLI entrypoint (bash wrapper)
├── lib/                    # Core library functions
├── templates/              # CLAUDE.md and .claude/ templates
│   ├── CLAUDE.md
│   └── .claude/
│       ├── rules/
│       ├── skills/
│       └── commands/
├── src/                    # TypeScript source (v2 - NEW)
│   ├── cli/                # Command handlers
│   ├── core/               # Business logic
│   └── integrations/       # Obsidian, GitHub, Claude
├── tests/                  # BATS tests (bash) + Jest (TS)
└── CLAUDE.md               # This file
```

---

## Development Commands

```bash
# Current (bash)
./bin/claw --help           # Show help
./tests/bats/bin/bats tests/*.bats  # Run tests

# v2 (TypeScript - when implemented)
npm install                 # Install dependencies
npm run build               # Build TypeScript
npm test                    # Run tests
npm run dev                 # Development mode
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
     path="Projects/claw/2026-01-31-v2-orchestration-tool/_overview.md",
     oldString="| 1.1 | CLI scaffold | ⏳ Pending |",
     newString="| 1.1 | CLI scaffold | ✅ Complete |"
   )
   ```
2. Update "Live Progress Tracker" counts
3. Update "**Current Task:**" to next task
4. Add entry to "Session Log"

---

## Related Documentation

All in Obsidian at `Projects/claw/`:
- `research-2026-01-31-market-analysis.md` - Market research
- `problem-statement-2026-01-31.md` - Engineering problem statement
- `design-2026-01-31-orchestration-tool-v2.md` - Technical architecture
- `2026-01-31-v2-orchestration-tool/_overview.md` - Active session tracker

---

*Claw project — building the orchestration layer for autonomous AI development*
