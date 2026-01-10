---
description: (DEPRECATED - Use /auto instead) Full autonomous mode - discover, plan, execute, ship
---

# /auto-pilot (DEPRECATED)

> **⚠️ DEPRECATED:** `/auto-pilot` has been renamed to `/auto`.
>
> Please update your workflows to use `/auto` instead.

## Migration Guide

```bash
# Old command (deprecated)
/auto-pilot --hours 4
/auto-pilot --discover-only
/auto-pilot --discovery none

# New command (recommended)
/auto --hours 4
/auto --plan-only
/auto --skip-discovery
```

## What Changed

| Old `/auto-pilot` | New `/auto` | Notes |
|-------------------|-------------|-------|
| `--discover-only` | `--plan-only` | More accurate naming |
| `--discovery none` | `--skip-discovery` | Clearer intent |
| `/plan-day` calls `/auto-pilot` | `/plan-day` calls `/auto --plan-only` | Alias updated |

## Full Documentation

See `/auto` or `.claude/commands/auto.md` for complete documentation.

---

**This deprecation notice will be removed in a future version.**
