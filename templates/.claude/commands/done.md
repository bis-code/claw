---
description: Mark current issue as complete, create PR, and suggest next
---

# Complete Current Issue

1. **Verify tests pass** for the current work:
   ```bash
   go test ./...
   npm run test:run
   ```

2. **Commit changes** with proper format:
   ```bash
   git add -A
   git commit -m "<type>(<scope>): description

   Closes #<issue>

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

3. **Create Pull Request** for this issue:
   ```bash
   git push -u origin issue/<number>-<slug>
   gh pr create --title "<type>(<scope>): description" --body "Closes #<number>"
   ```

4. **Update daily state file**:
   - Move issue from Active to Completed
   - Record PR number and link

5. **Update GitHub**: Remove `in-progress` label
   ```bash
   gh issue edit <number> --remove-label "in-progress"
   ```

6. **Suggest next issue** (on fresh branch from main), or offer to run `/ship-day` if plan is complete.

Reference `.claude/skills/daily-workflow/done.md` for full details.
