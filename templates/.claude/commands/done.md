---
description: Mark current issue as complete and suggest next
---

# Complete Current Issue

1. **Verify tests pass** for the current work:
   ```bash
   go test ./...
   npm run test:run
   ```

2. **Commit changes** (can be messy - will be squashed at end of day):
   ```bash
   git add -A
   git commit -m "wip: #<issue> <brief description>"
   ```

3. **Update daily state file**:
   - Move issue from Active to Completed
   - Add completion timestamp and notes

4. **Update GitHub**: Remove `in-progress` label
   ```bash
   gh issue edit <number> --remove-label "in-progress"
   ```

5. **Suggest next issue** from today's plan, or offer to run `/ship-day` if plan is complete.

Reference `.claude/skills/daily-workflow/done.md` for full details.
