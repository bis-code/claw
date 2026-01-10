---
name: wind-down
description: Daily wind-down and progress tracking
---

# Wind-Down Command

End your day with a structured brain dump and progress review.

## Usage

```bash
# Run interactive wind-down
/wind-down

# Skip if already done today
/wind-down --skip-if-done
```

## What It Does

1. **Scans your commits** from configured git directories
2. **Prompts for quick brain dump**:
   - Work done today
   - Personal done today
   - Tomorrow's priorities
   - Energy level (1-10)
   - What's stealing focus
3. **Saves to daily note** (Obsidian or `~/.claw/daily/`)

## Time-Aware Integration

This command works with claw's time-awareness system:

- **Morning**: Claude asks about gym plans, sets cutoff time
- **Before cutoff**: Claude warns you (15min, 5min)
- **At cutoff**: Terminal auto-opens with wind-down prompt
- **After cutoff**: Claude reminds you to wind down

## Configuration

Wind-down settings in `~/.claw/wind-down.conf`:

```bash
# Daily note location
OBSIDIAN_VAULT_PATH="$HOME/Documents/Obsidian/Daily"

# Git directories to scan
GIT_WORK_DIR="$HOME/work"
GIT_PERSONAL_DIR="$HOME/som"

# Cutoff times
GYM_DEFAULT_TIME="21:00"  # 9pm
GYM_DAY_CUTOFF="20:30"    # 8:30pm
NO_GYM_CUTOFF="22:00"     # 10pm
```

## Manual Wind-Down Script

You can also run the shell script directly:

```bash
# From anywhere
~/bin/wind-down.sh

# Or if installed via claw
claw wind-down
```

## Automation

The system includes automatic triggers:
- **Notifications** at cutoff time
- **Terminal auto-open** with wind-down script
- **Shell warnings** when opening terminal after hours

Manage automation:
```bash
# Check status
launchctl list | grep winddown

# Disable auto-open
launchctl unload ~/Library/LaunchAgents/com.winddown.auto-830pm.plist
launchctl unload ~/Library/LaunchAgents/com.winddown.auto-10pm.plist

# Re-enable
launchctl load ~/Library/LaunchAgents/com.winddown.auto-830pm.plist
launchctl load ~/Library/LaunchAgents/com.winddown.auto-10pm.plist
```

## Philosophy

Designed for **ADHD time-blindness**:
- External reminders (you lose track)
- Structured prompts (no blank page)
- Quick execution (2-3 minutes max)
- Gentle persistence (multiple warnings)
- Immediate value (see commits, set priorities)

**Not punishment, but support.**

## See Also

- Skill definition: `.claude/skills/wind-down/wind-down.md`
- Time-awareness rules: `.claude/rules/time-awareness.md`
- Setup guide: `docs/wind-down-setup.md`
- Integration plan: `docs/wind-down-integration-plan.md`

---

**Quick brain dump in 2-3 minutes, back to life.**
