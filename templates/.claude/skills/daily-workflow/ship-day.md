# /ship-day

End of day: squash commits, create PR, and close issues.

## What This Skill Does

1. Verifies all tests pass
2. Reviews the day's commits
3. **Lists completed items with high-priority review flags**
4. Proposes squash structure
5. Performs interactive squash into clean, themed commits
6. Creates a daily PR that closes multiple issues
7. Updates GitHub labels on all affected issues
8. Archives the daily state file with summary

## Invocation

```
/ship-day
```

Or with a theme:

```
/ship-day "Billing & Payment improvements"
```

---

## Steps

### 1. Pre-Flight Checks

```bash
# Check for uncommitted changes
git status

# Run all tests
go test ./...
npm run test:run

# Verify on daily branch
git branch --show-current
```

**If issues found:**
- Uncommitted changes → Offer to commit as WIP
- Failing tests → Must fix before shipping
- Wrong branch → Warn and confirm

### 2. Review Day's Work

```bash
git log --oneline main..HEAD
```

Display:
- All commits made today
- Issues marked as completed in state file
- Pivots that occurred
- Time spent (if tracked)

### 3. High-Priority Review Checklist

Before shipping, list ALL completed items and flag those requiring extra scrutiny:

```
Completed Today:
────────────────
✅ #42 - Add payment modal
   🔴 HIGH PRIORITY - Billing/Payment changes
   → Review: Stripe integration, error handling, PCI compliance

✅ #38 - Fix checkout validation
   🔴 HIGH PRIORITY - Revenue flow affected
   → Review: Edge cases, error messages, user experience

✅ #55 - Update dashboard layout
   🟢 LOW PRIORITY - UI only
   → Quick visual check sufficient

✅ #61 - Add license tier migration
   🔴 HIGH PRIORITY - License/Security changes
   → Review: Data preservation, tier enforcement, rollback plan
```

**High-Priority Categories** (always flag these):
| Category | Why Review |
|----------|------------|
| Billing/Payment | Revenue impact, PCI compliance |
| License/Activation | Security, abuse prevention |
| Auth/Security | Access control, data protection |
| Database migrations | Data integrity, rollback plan |
| External API changes | Breaking changes, rate limits |
| Cross-service contracts | Integration stability |

**Review Actions:**
- Run `make dev` and manually verify high-priority flows
- Check for console errors in browser
- Verify edge cases mentioned in issue description
- Confirm rollback plan exists for database changes

### 4. Propose Squash Structure

Based on completed issues and commit messages, suggest groupings:

```
Today's commits (8 total):
  abc123 wip: payment modal setup
  def456 wip: stripe elements
  ghi789 fix: element styling
  jkl012 wip: error handling
  mno345 fix: checkout validation
  pqr678 wip: 3d secure
  stu901 fix: tests
  vwx234 docs: update readme

Proposed squash structure:
  1. feat(billing): add payment method update modal (#42)
     - Combines: abc123, def456, ghi789, pqr678, stu901

  2. fix(checkout): improve error handling and validation (#38)
     - Combines: jkl012, mno345

  3. docs: update billing documentation
     - Combines: vwx234

Does this look right? [y/n/modify]
```

### 5. Perform Squash

Using non-interactive rebase with the approved structure:

```bash
# Create backup tag
git tag backup-$(date +%Y-%m-%d) HEAD

# Perform squash (automated based on approval)
git reset --soft main
git commit -m "feat(billing): add payment method update modal (#42)

- Add Stripe Elements integration
- Implement 3D Secure flow
- Add comprehensive test coverage

Closes #42

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

# ... repeat for other squashed commits
```

### 6. Create PR

```bash
gh pr create \
  --title "Daily: $(date +%Y-%m-%d) - Billing & Payment improvements" \
  --body "$(cat <<'EOF'
## Daily Sprint: 2025-12-30

### Theme
Billing & Payment improvements

### Issues Addressed
- Closes #42 - Add payment method update modal
- Closes #38 - Fix checkout error handling

### Changes Summary
- Added Stripe Elements integration for payment method updates
- Implemented 3D Secure authentication flow
- Improved checkout error messages and validation

### Pivots & Decisions
- 10:45: Scope increase on #42 - Added 3D Secure (security requirement)
- 11:30: AI restructuring - Combined modal work with #45 prep

### Perspective Insights
- **Product**: Completes billing story for v1
- **CTO**: Stripe Elements approach is PCI-compliant
- **Sales**: Addresses enterprise customer requests

### Test Coverage
- [x] All new code has tests
- [x] Test hooks passed

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" \
  --base main
```

### 7. Update GitHub Issues

For completed issues (close and clean up labels):
```bash
gh issue close 42 --comment "Completed in PR #123"
gh issue edit 42 --remove-label "in-progress"
gh issue close 38 --comment "Completed in PR #123"
gh issue edit 38 --remove-label "in-progress"
```

For deferred issues:
```bash
gh issue comment 45 --body "Deferred from 2025-12-30 sprint. Reason: Blocked by #42 completion. Will prioritize tomorrow."
gh issue edit 45 --remove-label "in-progress"
```

### 8. Archive Daily File

Update `.claude/daily/YYYY-MM-DD.md`:

```markdown
## End of Day

status: completed
pr: #123
commits_squashed: 8
issues_closed: [42, 38]
issues_deferred: [45]
total_pivots: 2
theme: Billing & Payment improvements

### Retrospective
- Estimated: 6 hours
- Actual: 5.5 hours
- Velocity: Good - 3D Secure added without delay

### Patterns Learned
- Stripe Elements setup is reusable for future payment work
- BillingModal component ready for invoice features tomorrow
```

---

## Dry Run Mode

To preview without making changes:

```
/ship-day --dry-run
```

This shows:
- What the squash structure would be
- What the PR would look like
- What labels would change

---

## Rollback

If something goes wrong after shipping:

```bash
# Reset to backup
git reset --hard backup-$(date +%Y-%m-%d)

# Delete the backup tag when done
git tag -d backup-$(date +%Y-%m-%d)
```
