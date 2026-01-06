# claw - Claude Automated Workflow

A CLI tool that supercharges Claude Code with intelligent project detection, AI agent brainstorming, and semantic code search.

## Project Status (v0.4.3)

**What's Working:**
- Intelligent project type detection (17+ project types)
- Agent roster with 17 specialized AI personas for brainstorming
- LEANN semantic search integration
- Multi-repo project support
- Auto-generated slash commands (`/brainstorm`, `/plan-day`, `/search`)
- 165 passing tests

## Features

| Feature | Description |
|---------|-------------|
| **Project Detection** | Automatically identifies Unity, Godot, SaaS, Web3, ML, API, mobile, desktop, and more |
| **Agent Brainstorming** | 17 specialized agents (Senior Dev, Product, CTO, QA, Security, etc.) for multi-perspective analysis |
| **LEANN Search** | Semantic code search powered by local embeddings |
| **Multi-Repo** | Coordinate work across related repositories |
| **Presets** | Quick setup with full, base, slim, hardhat, unity, react presets |

## Quick Start

### Installation

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

### Per-Project Setup

```bash
cd your-project
claw init              # Auto-detects project type
claw init --preset unity   # Or specify a preset
```

### Ongoing Usage

```bash
# In Claude Code, use the slash commands:
/brainstorm    # Start multi-agent brainstorming session
/plan-day      # Plan your day based on GitHub issues
/search query  # Semantic search across codebase
```

## Commands

```bash
claw init [--preset <name>]   # Initialize Claude config
claw detect                   # Detect project type
claw upgrade                  # Upgrade existing config
claw agents list              # List available agents
claw agents spawn <name>      # Show agent prompt
claw leann status             # Show LEANN status
claw leann build              # Build search index
claw multi-repo detect        # Detect sibling repos
claw version                  # Show version
claw help                     # Show help
```

## Project Detection

claw automatically detects your project type and recommends appropriate agents:

| Type | Detection | Recommended Agents |
|------|-----------|-------------------|
| `game-unity` | `ProjectSettings/`, `.unity` files | gameplay-programmer, systems-programmer, technical-artist |
| `game-godot` | `project.godot` | gameplay-programmer, systems-programmer, tools-programmer |
| `saas` | Next.js + Stripe/Auth | senior-dev, product, ux, security |
| `web3` | Hardhat/Foundry | senior-dev, security, auditor |
| `data-ml` | PyTorch/TensorFlow | data-scientist, mlops, senior-dev |
| `api` | Express/FastAPI/NestJS | api-designer, senior-dev, security |
| `mobile` | React Native/Expo | mobile-specialist, ux, qa |
| `desktop` | Electron/Tauri | desktop-specialist, ux, senior-dev |
| `cli` | Has `bin` or `cmd/` | senior-dev, docs, qa |
| `library` | Publishable package | senior-dev, docs, api-designer |

## Agent Roster

17 specialized agents provide different perspectives during brainstorming:

**General:**
- `senior-dev` - Code architecture, patterns, technical debt
- `product` - User value, prioritization, MVP scope
- `cto` - Technical strategy, scalability, team considerations
- `qa` - Testing strategies, edge cases, quality gates
- `ux` - User experience, accessibility, interaction design
- `security` - Vulnerabilities, compliance, secure coding
- `docs` - Documentation, API design, developer experience
- `api-designer` - REST/GraphQL design, versioning, contracts

**Game Development:**
- `gameplay-programmer` - Game mechanics, player feel, systems
- `systems-programmer` - Core systems, performance, memory
- `tools-programmer` - Editor tools, automation, pipeline
- `technical-artist` - Shaders, VFX, rendering optimization

**Specialized:**
- `data-scientist` - ML models, data pipelines, experiments
- `mlops` - Model deployment, monitoring, infrastructure
- `mobile-specialist` - Mobile-specific patterns, performance
- `desktop-specialist` - Desktop app patterns, native integration
- `auditor` - Smart contract security, formal verification

## LEANN Integration

LEANN provides semantic code search using local embeddings:

```bash
# Check status
claw leann status

# Build index for current project
claw leann build

# Search (via Claude Code slash command)
/search "authentication flow"
```

## Multi-Repo Support

For projects split across multiple repositories:

```bash
# Detect sibling repos (e.g., frontend, backend, contracts)
claw multi-repo detect

# Create shared config
claw multi-repo config

# Fetch issues from all repos
claw multi-repo issues
```

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

## Presets

| Preset | Best For |
|--------|----------|
| `full` | All features enabled |
| `base` | Standard configuration |
| `slim` | Minimal setup |
| `hardhat` | Web3/Solidity development |
| `unity` | Unity game development |
| `react` | React/Next.js web apps |

## Requirements

- Bash 4.0+
- Claude Code CLI
- Git
- Optional: LEANN (`uvx leann`), GitHub CLI (`gh`)

## Development

```bash
# Run tests
make test

# Run all tests including external deps
make test-all

# Setup dev environment
make setup
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Submit PR with appropriate label (`feature`, `fix`, `docs`, `chore`)

## License

MIT
