# claw - Command Line Automated Workflow

A powerful wrapper for Claude Code that adds project management, multi-repo support, and autonomous development workflows.

## Quick Start

```bash
# Install
brew tap bis-code/tap && brew install claw

# Use (drop-in replacement for claude)
claw                      # Start interactive session
claw "fix the bug"        # Start with prompt
claw --continue           # Continue last session
```

## Features

| Feature | Description |
|---------|-------------|
| **Project Management** | Group multiple repos into projects |
| **Multi-Repo Issues** | Aggregate GitHub issues across all project repos |
| **Daily Workflow** | `/plan-day`, `/ship-day`, `/brainstorm` commands |
| **Templates** | Install GitHub issue templates via API |
| **Auto-Detection** | Knows which project you're in from any subdirectory |

## Project-Based Multi-Repo

The recommended way to work with multiple repositories:

```bash
# Create a project
claw project create my-saas --description "My SaaS Platform"

# Add your local repos
claw project add-repo ~/projects/my-saas/api --project my-saas
claw project add-repo ~/projects/my-saas/dashboard --project my-saas
claw project add-repo ~/projects/my-saas/worker --project my-saas

# View project
claw project show
```

**Auto-detection:** Once configured, claw knows your project from any repo:

```bash
cd ~/projects/my-saas/api
claw project show          # Shows "my-saas" automatically
claw project issues        # Fetches issues from ALL repos in project
```

### Project Commands

| Command | Description |
|---------|-------------|
| `claw project create <name>` | Create a new project |
| `claw project add-repo <path>` | Add local repo to project |
| `claw project remove-repo <path>` | Remove repo from project |
| `claw project list` | List all projects |
| `claw project show` | Show current project details |
| `claw project issues` | Fetch issues from all project repos |

## Daily Workflow Commands

These commands are available in every Claude session:

| Command | Purpose |
|---------|---------|
| `/plan-day --hours 4` | Plan today's work from GitHub issues |
| `/brainstorm` | Multi-agent analysis of issues |
| `/auto-pilot` | Full autonomous: discover, plan, execute, ship |
| `/ship-day` | End of day: create PR, close issues |
| `/next` | Pick up next issue from plan |
| `/done` | Mark current issue complete |

### Example Workflow

```bash
# Morning: Start claw from any project repo
cd ~/projects/my-saas/api
claw

# Inside Claude session:
/plan-day --hours 6        # Plan the day
# ... work on issues ...
/done                      # After completing an issue
/next                      # Start next issue
/ship-day                  # End of day
```

## GitHub Issue Templates

Install Claude-ready issue templates to any repo:

```bash
# List available templates
claw templates list

# Install templates (uses GitHub API - no clone needed)
claw templates install myorg/myrepo bug-report claude-ready
```

Templates install directly to the default branch via API - works regardless of your local branch state.

### Available Templates

- **bug-report** - Bug reports with reproduction steps
- **feature-request** - Feature requests with acceptance criteria
- **claude-ready** - Tasks ready for `/plan-day` (labeled `claude-ready`)
- **tech-debt** - Technical debt tracking

## Legacy Multi-Repo (Simple)

For simpler needs, track repos by GitHub name:

```bash
claw repos add myorg/backend
claw repos add myorg/frontend
claw repos list
```

Issues from tracked repos are included in `/plan-day`.

## Configuration

claw stores data in `~/.claw/`:

```
~/.claw/
├── projects/           # Project configurations
│   └── my-saas/
│       └── config.json
├── repos.json          # Legacy tracked repos
└── daily/              # Daily workflow state files
```

Each repo in a project gets a `.claw/project.json` marker for auto-detection.

## Requirements

- [Claude Code CLI](https://claude.ai/code) (`claude`)
- [GitHub CLI](https://cli.github.com/) (`gh`) - for issue fetching and templates
- `jq` - for JSON processing

## All Options

```bash
claw --help               # Full usage
claw project --help       # Project management
claw repos --help         # Legacy multi-repo
claw templates --help     # Issue templates
claw --version            # Version info
claw --update             # Update global commands
```

## How It Works

1. **Wrapper**: claw passes all arguments to `claude`, adding features on top
2. **Projects**: Config stored in `~/.claw/projects/`, markers in each repo's `.claw/`
3. **Skills**: Global commands installed to `~/.claude/commands/`
4. **Templates**: Installed via GitHub API (no repo cloning)

## License

MIT
