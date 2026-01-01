# Setup Script Sync Rule

## Mandatory Sync Trigger

Whenever Claude modifies ANY of the following, the setup script MUST be regenerated:

- `CLAUDE.md`
- `.claude/settings.json`
- `.claude/hooks/*`
- `.claude/rules/*`
- `.claude/commands/*`
- `.claude/skills/*`
- `.claude/checklists/*`

## How to Sync

Run the export script after making changes:

```bash
/Users/baicoianuionut/som/personal-projects/useful-scripts/export-claude-setup.sh
```

## Automatic Reminder

A git pre-commit hook exists at `.git/hooks/pre-commit` that will:
1. Detect when Claude config files are being committed
2. Automatically regenerate the setup script
3. Remind you to commit the updated setup script

## Why This Matters

The portable setup script (`useful-scripts/setup-claude.sh`) is used to bootstrap new repositories with the same Claude configuration. If it gets out of sync:
- New repos will have outdated rules
- Bug fixes (like Bash compatibility) won't propagate
- New skills/commands won't be available

## Acknowledgement

After regenerating the setup script, acknowledge:
```
Setup script regenerated — useful-scripts/setup-claude.sh is in sync.
```
