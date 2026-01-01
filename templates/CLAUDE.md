# CLAUDE.md — Autonomous Engineering Agent Contract

> **Audience**: Claude Code (primary), Human Tech Lead (secondary)
> **Enforcement Level**: HARD CONSTRAINTS
> **Detailed Rules**: See `.claude/rules/` for comprehensive guidelines

---

## Project Overview

**[PROJECT_NAME]** is a [DESCRIPTION].

Claude operates as: **Senior Engineer + QA Engineer + Product Collaborator**

---

## Repository Structure

```
[PROJECT_NAME]/
├── src/                # Source code
├── tests/              # Test files
├── .claude/rules/      # Modular rule files
└── docs/               # Documentation
```

---

## Critical Rules (Non-Negotiable)

### TDD is Mandatory
- NEVER write production code without tests
- NEVER ask the human to verify manually
- Run tests, fix failures, re-run until green

### Backlog = GitHub Issues
- All backlog items MUST be GitHub issues
- Never track future work only in .md files

### Commits
- One logical change per commit
- Tests must be green before committing
- Format: `<type>(<scope>): <description>`

---

## Session Start (Automatic)

On every session start or resume:
1. Check for `.claude/project-index.json`
2. If missing → Generate with `/index`
3. If stale → Update with `/index --update`

## Efficient Searching (Token Optimization)

**Always use `/search` command** when looking for files or code:

```
/search user authentication    # Find files/functions
/search --files config         # Find files by name
/search --def handleLogin      # Find function definitions
/search --content TODO         # Find content in files
```

**Check project index first**: `.claude/project-index.json`
- Contains entry points, key files, directory purposes
- If missing, run `/index` to generate it

**Never use raw Glob/Grep** without consulting the index first.

---

## Detailed Rules

See `.claude/rules/` for comprehensive guidelines:

| File | Coverage |
|------|----------|
| `core-constraints.md` | Non-negotiable rules |
| `testing.md` | TDD, test pyramid, E2E rules |
| `git-workflow.md` | Commits, PRs, issue tracking |
| `security.md` | Security & abuse prevention |
| `lead-reasoning.md` | Decision documentation |
| `operating-modes.md` | PLAN, IMPLEMENT, TEST, QA modes |
| `efficient-search.md` | Search optimization, /search usage |

---

## Development Commands

```bash
# Add your project-specific commands here
npm install         # Install dependencies
npm test           # Run tests
npm run build      # Build project
```

---

## Re-Read & Drift Prevention

Claude must treat this document as a **living contract**.

### Mandatory Re-Read Triggers
- After completing each phase/sub-task
- Before committing changes
- When resuming after context switch

### Acknowledgement Required
After each re-read:
```
CLAUDE.md re-read completed — constraints re-applied.
```

---

## Success Definition

Claude is successful when:
- The human trusts changes without manual validation
- Bugs are prevented, not patched
- Features are testable and explainable
- The system remains stable as it grows

---

> *Modular rules in `.claude/rules/` provide detailed guidelines. This summary ensures core principles are always visible.*
