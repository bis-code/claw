# Git Workflow Rules

## Commit Format (Mandatory)

```
<type>(<scope>): <description>

[optional body]

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `test`: Adding tests
- `docs`: Documentation
- `chore`: Maintenance

### Scopes
- `highlights-api`, `license-api`, `dashboard`, `portal`, `desktop`

## Commit Rules

- One logical change per commit
- Tests must be green before committing
- No "WIP" commits
- No unrelated changes combined

## Before Merging Checklist (Claude-Owned)

- [ ] Tests written first
- [ ] Tests cover happy + unhappy paths
- [ ] Integration boundaries tested
- [ ] E2E tests added where required
- [ ] All tests pass locally
- [ ] Commit messages are correct
- [ ] No TODOs left untracked

## Backlog & Issue Tracking

All new backlog items MUST be tracked as **GitHub issues**, not Markdown files.

### Create GitHub Issue When:
- A new feature is identified but not immediately prioritized
- A bug is discovered but not immediately addressed
- A "Coming Soon" feature is proposed
- A refactoring opportunity is identified
- Technical debt is recognized

### Issue Format
```
Title: [TYPE] Brief description

## Summary
[1-2 sentences]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Priority
[P0: Critical | P1: High | P2: Medium | P3: Low]
```

### Issue Labels (Mandatory for Claude-Created Issues)

All issues created by Claude MUST include:
1. **`claude-ready`** - Indicates the issue was created by Claude and is ready for autonomous work
2. **Relevant domain labels** based on the issue content:

| Label | Use When |
|-------|----------|
| `bug` | Reporting a defect or incorrect behavior |
| `enhancement` | Proposing improvements to existing features |
| `feature` | New functionality request |
| `refactor` | Code improvement without behavior change |
| `tech-debt` | Technical improvements needed |
| `docs` | Documentation updates |
| `test` | Test coverage improvements |
| `security` | Security-related issues |
| `billing` | Payment, subscription, or license-related |
| `ux` | User experience improvements |

**Example `gh` command:**
```bash
gh issue create --title "[BUG] License invalid after cancel" \
  --body "..." \
  --label "bug,billing,claude-ready,P0"
```
