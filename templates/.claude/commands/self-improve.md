---
name: self-improve
description: Autonomous code quality improvement without human interaction
---

# Self-Improve Command

Run autonomous codebase improvements without human oversight.

## Usage

```bash
# Run with default 2-hour budget
/self-improve

# Custom time budget
/self-improve --hours 4

# Focus on specific area
/self-improve --focus "test coverage"

# Dry run (report only, no changes)
/self-improve --dry-run
```

## What It Does

1. **Discovers** improvement opportunities (TODOs, test gaps, shellcheck warnings, complexity)
2. **Prioritizes** by safety, impact, and effort
3. **Implements** fixes with TDD approach
4. **Validates** all changes with tests
5. **Creates PR** with all improvements

## Safety Features

- Only makes safe changes (safety score >= 7)
- Requires all tests to pass
- Rolls back on failure
- Never modifies security-critical code
- Limits scope (max 2 hours, 20 commits)

## Options

- `--hours N` - Time budget in hours (default: 2)
- `--focus "area"` - Focus on specific area
- `--dry-run` - Report only, don't make changes
- `--max-commits N` - Max commits per run (default: 20)

## CI/CD Integration

Automatically runs daily via `.github/workflows/self-improve.yml`.

## See Also

- Skill definition: `.claude/skills/self-improve/self-improve.md`
- Manual improvements: `/plan-day` then `/autonomous`

---

**Full autonomy**: No human interaction required during execution.
