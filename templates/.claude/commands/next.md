---
description: Pick up the next issue from today's plan (on fresh branch)
---

# Pick Next Issue

1. **Switch to main and pull latest**:
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Read the current daily state file**: `~/.claw/daily/$(date +%Y-%m-%d).md`

3. **Find the next pending issue** in the plan (or use the issue number if specified)

4. **Create issue-specific branch**:
   ```bash
   git checkout -b issue/<number>-<short-slug>
   # Example: issue/42-payment-modal
   ```

5. **Move it to Active status** in the state file with timestamp and branch name

6. **Update GitHub**: Add `in-progress` label to the issue
   ```bash
   gh issue edit <number> --add-label "in-progress"
   ```

7. **Fetch and present issue context**:
   ```bash
   gh issue view <number>
   ```

   Show:
   - Description and acceptance criteria
   - Test strategy required
   - Relevant perspectives
   - Files likely to be touched

8. **Begin implementation** following TDD (tests first).

Reference `.claude/skills/daily-workflow/next.md` for full details.
