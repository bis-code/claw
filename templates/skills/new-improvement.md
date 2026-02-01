# /new-improvement - Suggest an Improvement

Create an improvement (refactor, tech-debt, performance, coverage) in Obsidian.

## Usage

```
/new-improvement
/new-improvement "Refactor auth module to use middleware pattern"
```

## Scope

Improvements cover non-feature, non-bug work:

| Category | Description | Examples |
|----------|-------------|----------|
| **refactor** | Restructure code, no behavior change | Extract class, rename module |
| **tech-debt** | Clean up hacks, TODOs, outdated patterns | Remove deprecated API, fix TODO |
| **performance** | Optimizations, speed improvements | Add caching, optimize query |
| **coverage** | Add missing tests | Unit tests for utils, E2E for flow |

## Flow

1. **Get description** (if not provided)
   - Ask: "What improvement do you want to make?"

2. **Get category**
   - Ask: "Category?" (refactor/tech-debt/performance/coverage)

3. **Clarify approach** (for refactors)
   - Ask: "What's the target state?"

4. **Create in Obsidian**
   - Path: `improvements/<slug>.md`
   - Use note format below

5. **Team mode: Create GitHub issue**
   - If `config.mode === 'team'`:
     - Create issue with label from `config.github.labels.improvement`
     - Add link to Obsidian note in issue body
     - Add issue number to Obsidian note

## Improvement Note Format

```markdown
# Improvement: <title>

**Category:** refactor | tech-debt | performance | coverage
**Status:** pending
**Created:** YYYY-MM-DD
**GitHub:** #123 (if team mode)

## Description

<what needs to be improved>

## Current State

<how it works now, what's wrong>

## Target State

<how it should work after>

## Approach

1. <step 1>
2. <step 2>
3. <step 3>

## Risks

- <potential issue>
- <what could break>

## Verification

- [ ] Existing tests pass
- [ ] New tests added (if needed)
- [ ] No behavior change (for refactors)
- [ ] Performance measured (for optimizations)

## Notes

<additional context>
```

## Category Guidelines

### Refactor
- No behavior change
- Tests should pass before and after
- Often enables future features
- Example: "Extract payment logic into PaymentService"

### Tech-Debt
- Fixing past shortcuts
- Removing deprecated code
- Updating outdated patterns
- Example: "Replace moment.js with date-fns"

### Performance
- Measurable improvement needed
- Profile before and after
- Consider trade-offs
- Example: "Add Redis caching for user sessions"

### Coverage
- Identify missing tests
- Focus on critical paths
- Don't test for coverage sake
- Example: "Add E2E tests for checkout flow"

## Configuration

From `.claw/config.json`:
- `mode`: 'solo' or 'team'
- `create.obsidian`: always true
- `create.github`: true in team mode
- `github.labels.improvement`: label for improvement issues
- `obsidian.vault`: path to vault
- `obsidian.project`: project folder in vault
