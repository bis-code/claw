# /auto-pilot (DEPRECATED)

> **⚠️ DEPRECATED:** `/auto-pilot` has been renamed to `/auto`. Please update your workflows.
>
> **Migration:** Replace `/auto-pilot` with `/auto` in your scripts and commands.

---

## Redirect to /auto

This command now redirects to `/auto`. All functionality has been consolidated:

```bash
# Old (deprecated)
/auto-pilot --hours 4

# New (recommended)
/auto --hours 4
```

## What Changed

- **Command name**: `/auto-pilot` → `/auto`
- **Flags**: Same flags, but added:
  - `--plan-only` (replaces `--discover-only`)
  - `--skip-discovery` (alias for `--discovery none`)
- **Aliases**: `/plan-day` now calls `/auto --plan-only`
- **Internal commands**: `/brainstorm` and `/autonomous` are now internal

## Full Documentation

See `.claude/skills/daily-workflow/auto.md` or `.claude/commands/auto.md` for complete details.

---

**This deprecation notice will be removed in a future version. Please update your workflows to use `/auto` instead.**
