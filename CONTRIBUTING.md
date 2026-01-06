# Contributing to Claw

Thank you for your interest in contributing to Claw! This document provides guidelines for contributing.

## Getting Started

### Prerequisites

- Bash 4.0+ (macOS users: `brew install bash`)
- [jq](https://stedolan.github.io/jq/) for JSON processing
- [BATS](https://github.com/bats-core/bats-core) for testing

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/claw.git
   cd claw
   ```
3. Set up test dependencies:
   ```bash
   git clone --depth 1 https://github.com/bats-core/bats-core.git tests/bats
   git clone --depth 1 https://github.com/bats-core/bats-support.git tests/test_helper/bats-support
   git clone --depth 1 https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert
   ```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Changes

- Follow TDD: Write tests first, then implement
- Keep changes focused and atomic
- Update documentation if needed

### 3. Run Tests

```bash
# Run all tests
./tests/bats/bin/bats tests/*.bats tests/autonomous/*.bats

# Run specific test file
./tests/bats/bin/bats tests/autonomous/executor.bats

# Run with verbose output
./tests/bats/bin/bats -t tests/autonomous/*.bats
```

### 4. Commit Changes

Use conventional commit format:

```
feat(executor): add retry logic for failed tasks
fix(feedback): handle pytest output parsing
docs: update README with new commands
test(blocker): add tests for rate limit detection
```

### 5. Submit Pull Request

- Push your branch to your fork
- Create a Pull Request against `main`
- Fill out the PR template
- Wait for CI to pass

## Code Style

### Shell Scripts

- Use `set -euo pipefail` at the start
- Quote variables: `"$var"` not `$var`
- Use `[[` for conditionals (bash-specific)
- Add comments for non-obvious logic

### Testing

- Every feature needs tests
- Test both success and failure cases
- Use descriptive test names
- Keep tests independent (no shared state)

Example test:
```bash
@test "executor: add_task returns unique ID" {
    cd "$TMP_DIR"
    init_task_queue

    local id1 id2
    id1=$(add_task "Task 1" "high")
    id2=$(add_task "Task 2" "high")

    [[ "$id1" != "$id2" ]]
}
```

## Project Structure

```
claw/
├── bin/claw              # Main CLI entry point
├── lib/
│   ├── core.sh           # Core utilities
│   ├── detect.sh         # Project detection
│   └── autonomous/       # Autonomous execution modules
│       ├── executor.sh   # Task queue & execution
│       ├── feedback.sh   # Test runner & error parsing
│       ├── blocker.sh    # Blocker detection & resolution
│       └── checkpoint.sh # State persistence
├── tests/
│   ├── *.bats            # Core tests
│   └── autonomous/       # Autonomous module tests
└── templates/            # Claude Code templates
```

## Need Help?

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Be respectful and constructive

## License

By contributing, you agree that your contributions will be licensed under the project's license.
