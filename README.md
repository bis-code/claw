# claw - Command Line Automated Workflow

Just type `claw` instead of `claude`. That's it.

## Install

```bash
brew tap bis-code/tap
brew install claw
```

Or manually:
```bash
git clone https://github.com/bis-code/claw.git
./claw/install.sh
```

## Use

```bash
claw                      # Start chatting
claw "fix the bug"        # Start with prompt
claw --continue           # Continue last session
claw --resume <id>        # Resume specific session
```

## What you get

- **Global commands** available everywhere: `/plan-day`, `/ship-day`, `/brainstorm`
- **Session ID on exit** so you can resume later
- **Multi-repo tracking** to aggregate issues across projects

## Multi-repo

Track issues across multiple repos:

```bash
claw repos add myorg/backend
claw repos add myorg/frontend
claw repos list
```

Now `/plan-day` shows issues from all tracked repos.

## That's it

claw is a thin wrapper around Claude Code. All claude arguments work the same.

```bash
claw --help               # See options
claw repos --help         # Multi-repo help
```

## Requirements

- Claude Code CLI (`claude`)
- GitHub CLI (`gh`) for issue fetching

## License

MIT
