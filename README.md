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

claw is designed to grow with your needs. Start simple, add capabilities as you need them.

### Level 1: Basic Setup

Just want Claude Code configured? One command:

```bash
cd your-project
claw init
```

**What you get:**
- `.claude/` directory with slash commands
- `CLAUDE.md` project instructions file
- Auto-detected project type and preset

**Use in Claude Code:**
```
/brainstorm    # Get multi-perspective feedback on ideas
```

---

### Level 2: Agent Brainstorming

Want AI personas to debate your decisions? Check what agents are recommended:

```bash
claw detect                    # See your project type
claw agents list               # See recommended agents
claw agents spawn senior-dev   # Preview an agent's prompt
```

**Example output:**
```
Project Type: saas
Recommended Agents: senior-dev product cto qa ux security
```

**Use in Claude Code:**
```
/brainstorm Should we use Redis or PostgreSQL for sessions?
```

The agents will debate from their perspectives (Security will worry about expiry, DevOps about ops overhead, etc.)

---

### Level 3: Semantic Search

Want to search your codebase by meaning, not just keywords?

```bash
# Check if LEANN is installed
claw leann status

# If not installed:
pip install leann   # or: uvx leann

# Build the search index
claw leann build
```

**Use in Claude Code:**
```
/search "where is user authentication handled"
/search "database connection pooling"
```

---

### Level 4: Multi-Repo Projects

Working across multiple related repositories?

```bash
# From any repo in the group
claw multi-repo detect
```

**How detection works (in priority order):**

1. **Prefix matching** - If you're in `myapp-frontend`, finds `myapp-backend`, `myapp-api`
2. **Git siblings** - Finds any sibling folders with `.git` directories
3. **Pattern matching** - Finds folders named `frontend`, `backend`, `api`, `contracts`, etc.

**Example output:**
```json
{
  "detected": true,
  "prefix": "myapp",
  "siblings": [
    {"name": "myapp-backend", "type": "api"},
    {"name": "myapp-contracts", "type": "web3"}
  ]
}
```

**Coordinate across repos:**
```bash
claw multi-repo config     # Create shared config
claw multi-repo issues     # Fetch issues from all repos
```

---

### Level 5: Daily Planning (GitHub integration)

Plan your day based on GitHub issues labeled for Claude:

```bash
# Requires: gh auth login
/plan-day
```

This fetches issues tagged `claude-ready` from your repo(s) and helps prioritize.

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
