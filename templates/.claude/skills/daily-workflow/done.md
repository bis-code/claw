# /done

Mark the current issue as complete.

## What This Skill Does

1. **RUNS /validate FIRST** (mandatory)
2. Verifies ALL tests pass (unit, integration, E2E)
3. Commits current changes (can be messy - will be squashed)
4. Moves issue from "Active" to "Completed" in state file
5. Updates GitHub label
6. Suggests next issue

## Invocation

```
/done
```

Or with a note:

```
/done "Implemented with Stripe Elements, added 3D Secure support"
```

Or force (use with caution):

```
/done --force --reason "Known issue, tracking in #45"
```

## Steps

### 0. MANDATORY: Run Validation First

**BEFORE ANYTHING ELSE**, invoke `/validate`:

```
/validate
```

This checks:
- Configuration consistency (API keys, env vars)
- ALL user flows work (not just unit tests)
- Edge cases based on feature type
- Cross-service integration

**If /validate fails:**
- DO NOT proceed
- Create GitHub issues for failures
- Report what needs to be fixed
- User must fix issues or use `--force`

See `/validate` for full validation checklists by feature type.

### 1. Verify Tests

Run ALL relevant tests (not just changed files):

```bash
# For Go services
cd apps/license-api && go test ./... -v
cd apps/highlights-api && go test ./... -v

# For Vue frontends
cd apps/license-portal && npm run test:run
cd apps/highlights-dashboard && npm run test:run

# E2E tests for the feature
cd apps/license-portal && npx playwright test [feature].spec.ts
```

**Tests MUST pass. No exceptions.**

### 2. Commit Changes

```bash
git add -A
git commit -m "wip: #42 payment modal"
```

Note: Commits during the day can be messy. They'll be squashed by `/ship-day`.

### 3. Update State File

Move issue from "Active" to "Completed":

```markdown
### Completed
- [x] #42 - Add payment method update modal
  - status: done
  - completed: 14:30
  - notes: Implemented with Stripe Elements, added 3D Secure support
  - commit: abc1234
```

### 4. Update GitHub

```bash
gh issue edit 42 --remove-label "in-progress"
# Note: Don't add done-today yet - that happens at ship time
```

### 5. Suggest Next

If there are more issues in today's plan:

```
✓ #42 completed!

Next in plan: #45 - Invoice download feature
  - Scope: S (30 min - 2 hours)
  - This builds on the modal you just created

Run /next to start, or /pivot if plans changed.
```

## Quick Retrospective

When marking done, Claude may offer a quick insight:

```
Quick note: This took 2 hours vs estimated 4.
The Stripe Elements setup you learned will speed up #45 too.
```
