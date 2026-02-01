# /claw-bug

Create a bug report in Obsidian (and GitHub in team mode).

## Usage

```
/claw-bug
/claw-bug "Login fails after timeout"
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
   - Ask: "Want to attach a screenshot? (paste image or 'skip')"
   - See "Image Handling" section below

5. **Create in Obsidian**
   - Path: `bugs/<slug>.md`
   - Use note format below

6. **Team mode: Create GitHub issue**
   - If `config.mode === 'team'`:
     - Create issue with label from `config.github.labels.bug`
     - Add link to Obsidian note in issue body
     - Add issue number to Obsidian note

## Image Handling

When user pastes an image or provides a path:

1. **Read the image** using the Read tool to verify it's valid
2. **Generate filename**: `bug-<slug>-<timestamp>.png`
3. **Copy to Obsidian attachments**:
   - Target: `<vault>/<project>/attachments/<filename>`
   - Use Bash: `cp "<source>" "<target>"`
4. **Reference in note**: `![[attachments/<filename>]]`

**Pasted images** appear as temporary files (e.g., `/var/folders/.../paste-XXX.png`).
The path is shown when user pastes - use that path to copy the file.

**Example flow:**
```
User: /claw-bug "Button doesn't work"
Claude: Priority? (P0/P1/P2/P3)
User: P2
Claude: How to reproduce?
User: Click the submit button
Claude: Want to attach a screenshot? (paste image or 'skip')
User: [pastes image - shows path like /var/folders/.../paste-123.png]
Claude: Got it! Let me save that screenshot and create the bug report.
[Copies image to Obsidian, creates note with ![[attachments/bug-button-doesnt-work-1706819200.png]]]
```

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

![[attachments/bug-<slug>-<timestamp>.png]]

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
- `obsidian.vault`: path to vault
- `obsidian.project`: project folder in vault
- `github.labels.bug`: label for bug issues (team mode)
