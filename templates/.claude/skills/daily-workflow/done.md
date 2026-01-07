# /done

Mark the current issue as complete and create a PR.

## What This Skill Does

1. **RUNS /validate FIRST** (mandatory)
2. Verifies ALL tests pass (unit, integration, E2E)
3. Commits current changes with proper message
4. **Creates a PR for this issue** (PR-per-issue workflow)
5. Moves issue from "Active" to "Completed" in state file
6. Updates GitHub labels
7. Suggests next issue (on a fresh branch from main)

**Note:** Each issue gets its own PR for easier review and verification.

**Note:** Completed items are tracked in `~/.claw/daily/YYYY-MM-DD.md` for `/summary` to display (spans all tracked repos).

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
git commit -m "feat(scope): description

Closes #42

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

Note: Use proper conventional commit format since each issue gets its own PR.

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

### 4. Create Pull Request

Push branch and create PR for this issue:

```bash
# Push the issue branch
git push -u origin issue/42-payment-modal

# Create PR linking to the issue
gh pr create --title "feat(scope): description" \
  --body "## Summary
- Brief description of changes

## Test Plan
- [ ] Tests pass
- [ ] Manual verification done

Closes #42

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

**PR Guidelines:**
- Title should match the commit message
- Body should summarize changes and link to issue
- Include test plan for verification

### 5. Update GitHub Labels

```bash
gh issue edit 42 --remove-label "in-progress"
# PR will auto-close the issue when merged
```

### 6. Suggest Next

If there are more issues in today's plan:

```
✓ #42 completed!
✓ PR #15 created: https://github.com/owner/repo/pull/15

Next in plan: #45 - Invoice download feature
  - Scope: S (30 min - 2 hours)
  - This builds on the modal you just created

Run /next to start on a fresh branch, or /pivot if plans changed.
```

**Important:** The next issue will start on a fresh branch from main, not the current branch.
This keeps each PR focused on a single issue.

## Quick Retrospective

When marking done, Claude may offer a quick insight:

```
Quick note: This took 2 hours vs estimated 4.
The Stripe Elements setup you learned will speed up #45 too.
```
