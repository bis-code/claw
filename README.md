# Claude Code Setup

A CLI tool to install, upgrade, and manage Claude Code configurations across multiple repositories.

## Features

- **Versioned configs** - Track which version is installed in each repo
- **Smart upgrades** - Only updates files you haven't modified
- **Conflict detection** - Preserves your local customizations
- **Template export** - Export your config from any repo to share

## Installation

### Homebrew (macOS/Linux)

```bash
brew tap yourusername/tap
brew install claude-code-setup
```

### Manual

```bash
git clone https://github.com/yourusername/claude-code-setup.git
cd claude-code-setup
./install.sh
```

## Usage

### Initialize a new project

```bash
cd my-project
claude-setup init
```

### Check for updates

```bash
claude-setup check
```

### Upgrade to latest version

```bash
# Preserves your modifications
claude-setup upgrade

# Force overwrite everything
claude-setup upgrade --force
```

### Export from your config repo

```bash
claude-setup export ~/projects/my-main-repo
```

### View status

```bash
claude-setup status
```

## What gets installed

```
.claude/
├── manifest.json       # Version tracking
├── settings.json       # Hook configuration
├── hooks/              # Pre/post tool hooks
├── rules/              # Behavioral rules
├── commands/           # Slash commands
├── skills/             # Complex workflows
├── checklists/         # Validation checklists
└── daily/              # Daily logs (gitkeep)
CLAUDE.md               # Main instructions
```

## Upgrade behavior

| Scenario | Behavior |
|----------|----------|
| New file in update | Created |
| Unchanged file | Updated automatically |
| Modified by you | Skipped (preserved) |
| With `--force` | Overwritten |

## Configuration

The manifest file (`.claude/manifest.json`) tracks:

- Installed version
- Generation timestamp
- File checksums (to detect modifications)

## Contributing

1. Fork the repository
2. Make your changes to templates in `templates/`
3. Bump version in `bin/claude-setup`
4. Submit PR

## License

MIT
