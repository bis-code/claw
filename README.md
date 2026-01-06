# claw - Claude Automated Workflow

![Version](https://img.shields.io/badge/version-0.4.3-blue)
![Tests](https://img.shields.io/badge/tests-165%20passing-green)
![License](https://img.shields.io/badge/license-MIT-brightgreen)

> **Supercharge Claude Code with project detection, agent brainstorming, and semantic search**

Detects your project type, recommends specialized AI agents for brainstorming, and adds semantic code search. Install once, use in any project.

## What's Working

- 17+ project types auto-detected (Unity, Godot, SaaS, Web3, ML, API, mobile, desktop, CLI, library)
- 17 specialized agents for multi-perspective brainstorming
- LEANN semantic search integration
- Multi-repo project detection
- Slash commands: `/brainstorm`, `/plan-day`, `/search`

## Installation

**Homebrew (recommended):**
```bash
brew tap bis-code/tap
brew install claw
```

**Manual:**
```bash
git clone https://github.com/bis-code/claude-code-setup.git
cd claude-code-setup
./install.sh --prefix ~/.local
```

---

## Usage Levels

Start simple, add capabilities as needed.

### Level 1: Basic Setup

```bash
cd your-project
claw init
```

Creates `.claude/` with slash commands and `CLAUDE.md`. Use `/brainstorm` in Claude Code.

---

### Level 2: Agent Brainstorming

```bash
claw detect                    # See project type
claw agents list               # See recommended agents
claw agents spawn senior-dev   # Preview agent prompt
```

Use `/brainstorm Should we use Redis or PostgreSQL?` - agents debate from their perspectives.

---

### Level 3: Semantic Search

```bash
claw leann status              # Check if LEANN installed
pip install leann              # Install if needed (restart Claude Code after)
claw leann build               # Build search index
```

Use `/search "authentication flow"` in Claude Code.

---

### Level 4: Multi-Repo Projects

```bash
claw multi-repo detect
```

Finds related repos by:
1. **Prefix** - `myapp-frontend` finds `myapp-backend`
2. **Git siblings** - Any `.git` folder in same parent
3. **Patterns** - Folders named `frontend`, `backend`, `api`, `contracts`

```bash
claw multi-repo config         # Create shared config
claw multi-repo issues         # Fetch issues from all repos
```

---

### Level 5: Daily Planning

```bash
/plan-day                      # Requires: gh auth login
```

Fetches issues tagged `claude-ready` and helps prioritize.

---

## Command Reference

| Command | Description |
|---------|-------------|
| `claw init` | Initialize Claude config (auto-detects project type) |
| `claw init --preset unity` | Initialize with specific preset |
| `claw detect` | Show detected project type and recommended agents |
| `claw upgrade` | Upgrade existing config to latest |
| `claw agents list` | List all available agents |
| `claw agents spawn <name>` | Show full prompt for an agent |
| `claw leann status` | Show LEANN installation status |
| `claw leann build` | Build semantic search index |
| `claw multi-repo detect` | Detect related repositories |
| `claw multi-repo config` | Create multi-repo configuration |
| `claw multi-repo issues` | Fetch issues from all repos |
| `claw version` | Show version |
| `claw help` | Show help |

## Project Types

claw detects 17+ project types and recommends appropriate agents:

| Type | Detection | Recommended Agents |
|------|-----------|-------------------|
| `game-unity` | `ProjectSettings/`, `.unity` | gameplay-programmer, systems-programmer, technical-artist |
| `game-godot` | `project.godot` | gameplay-programmer, systems-programmer, tools-programmer |
| `saas` | Next.js + Stripe/Auth | senior-dev, product, ux, security |
| `web3` | Hardhat/Foundry | senior-dev, security, auditor |
| `data-ml` | PyTorch/TensorFlow | data-scientist, mlops, senior-dev |
| `api` | Express/FastAPI/NestJS | api-designer, senior-dev, security |
| `mobile` | React Native/Expo | mobile-specialist, ux, qa |
| `desktop` | Electron/Tauri | desktop-specialist, ux, senior-dev |
| `cli` | Has `bin` or `cmd/` | senior-dev, docs, qa |
| `library` | Publishable package | senior-dev, docs, api-designer |
| `web` | React/Vue/Svelte | senior-dev, ux, product, qa |

## Agent Roster

17 specialized agents provide different perspectives:

**General:**
| Agent | Focus |
|-------|-------|
| `senior-dev` | Code architecture, patterns, technical debt |
| `product` | User value, prioritization, MVP scope |
| `cto` | Technical strategy, scalability, team considerations |
| `qa` | Testing strategies, edge cases, quality gates |
| `ux` | User experience, accessibility, interaction design |
| `security` | Vulnerabilities, compliance, secure coding |
| `docs` | Documentation, API design, developer experience |
| `api-designer` | REST/GraphQL design, versioning, contracts |

**Game Development:**
| Agent | Focus |
|-------|-------|
| `gameplay-programmer` | Game mechanics, player feel, systems |
| `systems-programmer` | Core systems, performance, memory |
| `tools-programmer` | Editor tools, automation, pipeline |
| `technical-artist` | Shaders, VFX, rendering optimization |

**Specialized:**
| Agent | Focus |
|-------|-------|
| `data-scientist` | ML models, data pipelines, experiments |
| `mlops` | Model deployment, monitoring, infrastructure |
| `mobile-specialist` | Mobile-specific patterns, performance |
| `desktop-specialist` | Desktop app patterns, native integration |
| `auditor` | Smart contract security, formal verification |

## Presets

| Preset | Best For |
|--------|----------|
| `full` | All features enabled |
| `base` | Standard configuration |
| `slim` | Minimal setup |
| `hardhat` | Web3/Solidity development |
| `unity` | Unity game development |
| `react` | React/Next.js web apps |

## What Gets Installed

```
your-project/
├── .claude/
│   ├── commands/
│   │   ├── brainstorm.md    # Multi-agent brainstorming
│   │   ├── plan-day.md      # Daily planning from issues
│   │   └── search.md        # Semantic search
│   └── skills/
└── CLAUDE.md                # Project instructions
```

## Requirements

- Bash 4.0+
- Claude Code CLI
- Git

**Optional (for enhanced features):**
- LEANN (`pip install leann` or `uvx leann`) - Semantic search
- GitHub CLI (`gh`) - Issue fetching, multi-repo coordination

## Development

```bash
make setup      # Install all dependencies
make test       # Run core tests (165 tests)
make test-all   # Run all tests including external deps
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Submit PR with label: `feature`, `fix`, `docs`, or `chore`

## License

MIT
