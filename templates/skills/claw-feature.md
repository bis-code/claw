# /claw-feature

Create a feature request in Obsidian (and GitHub in team mode).

## Usage

```
/claw-feature
/claw-feature "Add dark mode"
```

## Flow

1. **Get description** (if not provided)
   - Ask: "What feature do you want to add?"

2. **Clarify scope**
   - Ask: "What should it do specifically?"
   - Capture acceptance criteria

3. **Mockup/reference image** (optional)
   - Ask: "Have a mockup or reference image? (paste or 'skip')"
   - See "Image Handling" section below

4. **E2E tests needed?**
   - Ask: "Does this need E2E tests?" (yes/no)
   - Default: no (unless critical user flow)

5. **Create in Obsidian**
   - Path: `features/<slug>.md`
   - Use note format below

6. **Team mode: Create GitHub issue**
   - If `config.mode === 'team'`:
     - Create issue with label from `config.github.labels.feature`
     - Add link to Obsidian note in issue body
     - Add issue number to Obsidian note

## Image Handling

When user pastes an image or provides a path:

1. **Read the image** using the Read tool to verify it's valid
2. **Generate filename**: `feature-<slug>-mockup-<timestamp>.png`
3. **Copy to Obsidian attachments**:
   - Target: `<vault>/<project>/attachments/<filename>`
   - Use Bash: `cp "<source>" "<target>"`
4. **Reference in note**: `![[attachments/<filename>]]`

**Pasted images** appear as temporary files (e.g., `/var/folders/.../paste-XXX.png`).
The path is shown when user pastes - use that path to copy the file.

## After Implementation - Verification Screenshots

When a feature is implemented and verified working, prompt:
- "Feature working! Want to add a screenshot showing it in action?"
- If yes, save as `feature-<slug>-done-<timestamp>.png`
- Update the note with a "## Verification" section containing the screenshot

This documents the completed feature visually for future reference.

## Feature Note Format

```markdown
# Feature: <title>

**Status:** pending
**Created:** YYYY-MM-DD
**E2E Required:** yes/no
**GitHub:** #123 (if team mode)

## Description

<description>

## User Story

As a <user type>,
I want to <action>,
So that <benefit>.

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Mockup

![[attachments/feature-<slug>-mockup-<timestamp>.png]]

## Technical Notes

<implementation considerations>

## Dependencies

- <dependency 1>
- <dependency 2>

## Out of Scope

- <what this feature does NOT include>

## Verification

<!-- Added after implementation -->
![[attachments/feature-<slug>-done-<timestamp>.png]]
```

## When to Mark E2E Required

Mark yes for:
- Authentication/authorization flows
- Payment/checkout flows
- Critical user journeys
- Multi-step forms
- Features with complex state

Mark no for:
- Simple UI changes
- Internal tools
- Non-critical features
- Backend-only changes (use integration tests)

## Configuration

From `.claw/config.json`:
- `mode`: 'solo' or 'team'
- `obsidian.vault`: path to vault
- `obsidian.project`: project folder in vault
- `github.labels.feature`: label for feature issues (team mode)
