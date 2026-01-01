---
description: End the day - squash commits, create PR, close issues
---

# Ship Day - End of Day Shipping

1. **Pre-flight checks**:
   ```bash
   git status                    # No uncommitted changes
   go test ./...                 # All tests pass
   git branch --show-current     # On daily branch
   ```

2. **Review day's commits**:
   ```bash
   git log --oneline main..HEAD
   ```

3. **Propose squash structure** - Group commits by theme/issue:
   ```
   feat(billing): add payment modal (#42)
   fix(checkout): improve error handling (#38)
   ```

4. **On approval, perform squash**:
   - Create backup tag: `git tag backup-$(date +%Y-%m-%d)`
   - Squash commits into themed groups
   - Each commit references issues it addresses

5. **Create PR**:
   ```bash
   gh pr create \
     --title "Daily: $(date +%Y-%m-%d) - [Theme]" \
     --body "[Generated from daily state file]" \
     --base main
   ```

6. **Update GitHub issues**:
   - Add `done-today` label to completed issues
   - Remove `in-progress` labels
   - Comment on deferred issues with reason

7. **Archive daily state file** with PR link and summary.

Reference `.claude/skills/daily-workflow/ship-day.md` for full details.
