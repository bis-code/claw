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
| **Autonomous Self-Improvement** | Daily automated code quality improvements with PR creation |
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
| `claw project generate-self-improve-workflow` | Generate autonomous improvement workflows |

## Available Skills/Commands

All commands are available inside any Claude session started with `claw`. Use them with a `/` prefix.

### Daily Workflow

| Command | Flags | Description |
|---------|-------|-------------|
| `/plan-day` | `--hours N` (required)<br>`--brainstorm`<br>`--no-issues` | Plan the day's work from GitHub issues<br>Uses lens-based analysis (Value, Risk, Effort, Security) |
| `/next` | None | Pick up next issue from today's plan |
| `/done` | None | Mark current issue as complete, update status |
| `/ship-day` | None | End of day: squash commits, create PR, close issues |

### Autonomous Workflows

| Command | Flags | Description |
|---------|-------|-------------|
| `/auto-pilot` | `--hours N` (default: 4)<br>`--focus "area"`<br>`--discovery [deep\|shallow\|none]`<br>`--discover-only` | Full autonomous mode: discover work, plan, execute, ship<br>Runs entire development cycle without human interaction |
| `/self-improve` | `--hours N` (default: 2)<br>`--focus "area"`<br>`--dry-run`<br>`--max-commits N` (default: 20) | Autonomous code quality improvements<br>Discovers issues, researches best practices, creates PR |
| `/autonomous` | None | Execute tasks from queue with TDD and blocker handling |

### Analysis & Planning

| Command | Flags | Description |
|---------|-------|-------------|
| `/brainstorm` | None | Multi-agent collaborative planning with parallel analysis<br>Includes CTO, Senior Dev, UX, QA, Product Owner perspectives |
| `/pivot` | None | Handle mid-day changes: blocker, better idea, scope change<br>Documents reason and updates plan |

### Utilities

| Command | Flags | Description |
|---------|-------|-------------|
| `/search` | `<query>`<br>`--files`<br>`--def`<br>`--content` | Efficient codebase search (optimized for token usage) |
| `/index` | `--update` | Generate or update project index for faster searching |
| `/summary` | None | Generate daily work summary with commits and changes |
| `/benchmark-search` | None | Compare search efficiency (Glob/Grep vs /search) |

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

### Autonomous Mode Example

```bash
claw

# Let Claude discover and fix issues autonomously
/auto-pilot --hours 4

# Or just improve code quality
/self-improve --hours 2
```

## Autonomous Self-Improvement

Enable daily automated code quality improvements for your entire project:

### Prerequisites

Configure Claude OAuth for each repository in your project:

```bash
# For EACH repository, run:
cd ~/projects/my-saas/api
claude
/install-github-app

cd ~/projects/my-saas/dashboard
claude
/install-github-app

# Repeat for all repos in your project...
```

This sets up `CLAUDE_CODE_OAUTH_TOKEN` that workflows will use.

### Generate Workflows

```bash
# Generate workflows for all repos in your project
cd ~/projects/my-saas/api  # Any repo in the project
claw project generate-self-improve-workflow

# Review and commit workflows
cd ~/projects/my-saas/api
git add .github/workflows/self-improve.yml
git commit -m "feat: add autonomous self-improvement"
git push

# Repeat for other repos (or use generate-self-improve-workflow from any repo)
```

### What It Does

Every day at 2 AM UTC, each repo will:

1. **Discover** improvement opportunities:
   - TODOs, FIXMEs, HACKs in code
   - Modules without tests
   - Shellcheck warnings
   - Complex functions (>50 lines)
   - Code duplication
   - **Web research** for best practices and trends

2. **Prioritize** by safety, impact, and effort:
   - Only safe changes (safety score ≥ 7)
   - High-impact improvements first
   - Includes trend-based features from web research

3. **Implement** fixes autonomously:
   - TDD approach (test first)
   - Run tests after each change
   - Rollback on failure
   - Atomic commits per improvement

4. **Create PR** automatically:
   - Summary of all improvements
   - Test results
   - Web research findings
   - Ready for review

### Safety Features

- Only non-breaking changes
- All tests must pass before commit
- Automatic rollback on failure
- Time-limited execution (2 hours max)
- No security-critical code modifications
- Conservative approach to new dependencies

### Example PR Output

```
🤖 Automated improvements - 2026-01-09

Summary:
- 8 improvements committed (2 from web research)
- Test coverage: 65% → 72% (+7%)
- Shellcheck warnings: 8 → 2 (-75%)
- Security: Adopted 1 new best practice

Web Research Findings:
- Adopted bats-assert library for better test assertions
- Implemented secure temp file handling (OWASP 2026)

All tests passing ✓
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

## Development

### Quick Local Testing

For instant feedback during development:

```bash
# Enable dev mode (one time)
./dev-mode.sh on

# Now make changes and test instantly!
vim bin/claw
claw --version  # ⚡ Instant!

# Quick test
./dev-mode.sh test

# When done
./dev-mode.sh off
```

**Commands:**
- `./dev-mode.sh on` - Enable development mode (symlinks to working code)
- `./dev-mode.sh off` - Disable development mode
- `./dev-mode.sh status` - Check current mode
- `./dev-mode.sh test` - Quick functionality test
- `./dev-mode.sh full` - Run full test suite

**Documentation:**
- [LOCAL-TESTING.md](LOCAL-TESTING.md) - All testing methods
- [BRANCHING.md](BRANCHING.md) - Release workflow

## License

MIT
