---
description: Handle mid-day changes - blocker, better idea, scope change, or urgent addition
---

# Pivot - Handle Mid-Day Changes

Usage: `/pivot <type>` where type is one of:
- `blocker` - Current issue is blocked by something
- `idea` - Better approach discovered
- `scope` - Issue is bigger or smaller than expected
- `urgent #123` - Add urgent issue to today's plan
- `rethink` - AI suggests restructuring based on patterns

## Blocker Flow
1. Ask what's blocking and if it's resolvable today
2. If resolvable: Add blocker resolution as new task
3. If not: Mark blocked, add GitHub label, defer to tomorrow

## Better Idea Flow
1. Describe the better approach
2. Update plan with new approach
3. Log the pivot in daily file

## Scope Change Flow
1. Bigger or smaller? By how much?
2. If bigger: Split into sub-issues or defer
3. If smaller: Suggest adding another issue

## Urgent Addition Flow
1. Fetch issue details from GitHub
2. Ask what to bump from today's plan
3. Add urgent issue, update daily file

## AI Rethink Flow
- Suggest restructuring when patterns emerge
- Combine related issues, reorder for efficiency

All pivots are logged in the daily state file with timestamps and reasoning.

Reference `.claude/skills/daily-workflow/pivot.md` for full details.
