# /next

Pick up the next issue from today's plan on a fresh branch.

## What This Skill Does

1. **Switches to main and pulls latest** (fresh start)
2. **Creates issue-specific branch** (`issue/<number>-<slug>`)
3. Reads the current daily state file
4. Finds the next pending issue in the plan
5. Moves it to "Active" status
6. Updates GitHub label to `in-progress`
7. Provides context for starting work

**Branch Strategy:** Each issue gets its own branch from main.
This enables PR-per-issue workflow for easier review.

## Invocation

```
/next
```

Or to pick a specific issue:

```
/next #42
```

## Steps

### 1. Switch to Main and Pull Latest

```bash
git checkout main
git pull origin main
```

### 2. Read Current State

```bash
cat ~/.claw/daily/$(date +%Y-%m-%d).md
```

### 3. Find Next Issue

- If no specific issue requested, pick the first from "Queued"
- If issue specified, verify it's in today's plan

### 4. Create Issue Branch

```bash
# Create branch with issue number and slug
git checkout -b issue/42-payment-modal

# Branch naming convention:
# issue/<number>-<short-slug>
# Examples:
#   issue/42-payment-modal
#   issue/53-settings-display
#   issue/14-version-sync
```

### 5. Update State File

Move issue from "Queued" to "Active":

```markdown
### Active
- [ ] #42 - Add payment method update modal
  - status: in_progress
  - started: 10:30
  - branch: issue/42-payment-modal
  - notes:
```

### 6. Update GitHub

```bash
gh issue edit 42 --add-label "in-progress"
```

### 7. Provide Context

Fetch and summarize the issue:

```bash
gh issue view 42
```

Present:
- Description
- Acceptance criteria
- Test strategy
- Relevant perspectives
- Files likely to be touched (if inferable)

## AI Suggestions

When picking up an issue, Claude may offer:
- "This issue has UX perspective - consider accessibility"
- "Related to #38 which you completed earlier - can reuse patterns"
- "Test strategy is Unit + E2E - write unit tests first"
