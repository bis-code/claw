# Self-Improve Skill

**Fully autonomous codebase improvement - no human interaction required.**

## Purpose

Continuously improve code quality, test coverage, and documentation without human oversight. Designed to run in CI/CD pipelines as a daily maintenance task.

## Capabilities

- Discover improvement opportunities automatically
- Prioritize by impact and safety
- Implement fixes with TDD approach
- Run tests to validate changes
- Create atomic commits per improvement
- Auto-create PR when done

## Safety Features

- Only makes safe, non-breaking changes
- Requires all tests to pass before committing
- Creates checkpoint before each change
- Rolls back on test failure
- Limits scope to prevent runaway execution
- Never modifies security-critical code without review

## Usage

```bash
# Run autonomous self-improvement
claude /self-improve

# Focus on specific area
claude /self-improve --focus "test coverage"

# Dry run (report only, no changes)
claude /self-improve --dry-run

# Set time limit (default: 2 hours)
claude /self-improve --hours 2
```

## What It Does

1. **Discovery Phase** (10 min)
   - Scan for TODOs, FIXMEs, HACKs
   - Check test coverage gaps
   - Run static analysis (shellcheck)
   - Find code smells (long functions, duplication)

2. **Prioritization** (5 min)
   - Score issues by: safety, impact, effort
   - Select top N improvements that can be completed in time budget
   - Exclude risky changes (security, breaking API changes)

3. **Execution Phase** (remainder of time)
   - For each improvement:
     - Create checkpoint
     - Write failing test (if needed)
     - Implement fix
     - Run all tests
     - Commit if tests pass
     - Rollback if tests fail

4. **Ship Phase** (5 min)
   - Create PR with all improvements
   - Auto-assign reviewers
   - Link to discovery report

## Configuration

Set in `.claude/settings.json`:

```json
{
  "skills": {
    "self-improve": {
      "enabled": true,
      "maxHours": 2,
      "maxCommits": 20,
      "safetyLevel": "high",
      "excludePatterns": [
        "**/secrets/**",
        "**/credentials/**",
        "**/.env*"
      ]
    }
  }
}
```

## CI/CD Integration

See `.github/workflows/self-improve.yml` for automated daily runs.

## Improvement Categories

### Safe (Always Auto-Fix)
- Add missing tests for existing functions
- Fix shellcheck warnings
- Update outdated documentation
- Add error handling to unguarded code
- Extract long functions (>50 lines) to helpers
- Add missing input validation

### Review Required (Create PR)
- Refactor complex logic (>100 lines)
- Change function signatures
- Update dependencies
- Modify security-related code

### Never Auto-Fix
- Authentication/authorization logic
- Cryptographic operations
- Database migrations
- Breaking API changes
