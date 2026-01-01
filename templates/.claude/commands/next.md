---
description: Pick up the next issue from today's plan
---

# Pick Next Issue

1. **Read the current daily state file**: `.claude/daily/$(date +%Y-%m-%d).md`

2. **Find the next pending issue** in the plan (or use the issue number if specified as argument)

3. **Move it to Active status** in the state file with timestamp

4. **Update GitHub**: Add `in-progress` label to the issue
   ```bash
   gh issue edit <number> --add-label "in-progress"
   ```

5. **Fetch and present issue context**:
   ```bash
   gh issue view <number>
   ```

   Show:
   - Description and acceptance criteria
   - Test strategy required
   - Relevant perspectives
   - Files likely to be touched

6. **Begin implementation** following TDD (tests first).

Reference `.claude/skills/daily-workflow/next.md` for full details.
