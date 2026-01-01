# /next

Pick up the next issue from today's plan.

## What This Skill Does

1. Reads the current daily state file
2. Finds the next pending issue in the plan
3. Moves it to "Active" status
4. Updates GitHub label to `in-progress`
5. Provides context for starting work

## Invocation

```
/next
```

Or to pick a specific issue:

```
/next #42
```

## Steps

### 1. Read Current State

```bash
cat .claude/daily/$(date +%Y-%m-%d).md
```

### 2. Find Next Issue

- If no specific issue requested, pick the first from "Planned"
- If issue specified, verify it's in today's plan

### 3. Update State File

Move issue from "Planned" to "Active":

```markdown
### Active
- [ ] #42 - Add payment method update modal
  - status: in_progress
  - started: 10:30
  - notes:
```

### 4. Update GitHub

```bash
gh issue edit 42 --add-label "in-progress"
```

### 5. Provide Context

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
