# /new-feature - Propose a Feature

Create a feature request in Obsidian (and GitHub in team mode).

## Usage

```
/new-feature
/new-feature "Add dark mode"
```

## Flow

1. **Get description** (if not provided)
   - Ask: "What feature do you want to add?"

2. **Clarify scope**
   - Ask: "What should it do specifically?"
   - Capture acceptance criteria

3. **E2E tests needed?**
   - Ask: "Does this need E2E tests?" (yes/no)
   - Default: no (unless critical user flow)

4. **Create in Obsidian**
   - Path: `features/<slug>.md`
   - Use note format below

5. **Team mode: Create GitHub issue**
   - If `config.mode === 'team'`:
     - Create issue with label from `config.github.labels.feature`
     - Add link to Obsidian note in issue body
     - Add issue number to Obsidian note

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

## Technical Notes

<implementation considerations>

## UI/UX Notes

<design considerations, mockups>

## Dependencies

- <dependency 1>
- <dependency 2>

## Out of Scope

- <what this feature does NOT include>
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
- `create.obsidian`: always true
- `create.github`: true in team mode
- `github.labels.feature`: label for feature issues
- `obsidian.vault`: path to vault
- `obsidian.project`: project folder in vault
