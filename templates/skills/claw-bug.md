---
name: claw-bug
description: Report a bug
---

# /claw-bug

Create a bug report in Obsidian (and GitHub in team mode).

## Usage

```
/report-bug
/report-bug "Login fails after timeout"
```

## Flow

1. **Get description** (if not provided)
   - Ask: "What's the bug?"

2. **Get priority**
   - Ask: "Priority?" (P0/P1/P2/P3)
   - Default: P2

3. **Get reproduction steps** (optional)
   - Ask: "How to reproduce? (or skip)"

4. **Screenshot** (optional)
   - Ask: "Need to attach a screenshot?"
   - If yes, guide user to paste or provide path

5. **Create in Obsidian**
   - Path: `bugs/<slug>.md`
   - Use note format below

6. **Team mode: Create GitHub issue**
   - If `config.mode === 'team'`:
     - Create issue with label from `config.github.labels.bug`
     - Add link to Obsidian note in issue body
     - Add issue number to Obsidian note

## Bug Note Format

```markdown
# Bug: <title>

**Priority:** P2
**Status:** pending
**Created:** YYYY-MM-DD
**GitHub:** #123 (if team mode)

## Description

<description>

## Steps to Reproduce

1. <step>
2. <step>
3. <step>

## Expected Behavior

<what should happen>

## Actual Behavior

<what happens instead>

## Screenshots

<if any - use ![[attachments/filename.png]]>

## Environment

- Browser:
- OS:
- Version:

## Notes

<investigation notes, added during work>
```

## Priority Guide

| Priority | Meaning | Example |
|----------|---------|---------|
| P0 | Critical, blocking | App crashes on launch |
| P1 | High, major feature broken | Can't log in |
| P2 | Medium, workaround exists | Button misaligned |
| P3 | Low, minor annoyance | Typo in message |

## Configuration

From `.claw/config.json`:
- `mode`: 'solo' or 'team'
- `create.obsidian`: always true
- `create.github`: true in team mode
- `github.labels.bug`: label for bug issues
- `obsidian.vault`: path to vault
- `obsidian.project`: project folder in vault
