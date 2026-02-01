# /claw-improve

Create an improvement (refactor, tech-debt, performance, coverage) in Obsidian.

## Usage

```
/claw-improve
/claw-improve "Refactor auth module to use middleware pattern"
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

4. **Reference image** (optional, category-specific)
   - Refactors: "Have an architecture diagram? (paste or 'skip')"
   - Performance: "Have a before screenshot/benchmark? (paste or 'skip')"
   - See "Image Handling" section below

5. **Create in Obsidian**
   - Path: `improvements/<slug>.md`
   - Use note format below

6. **Team mode: Create GitHub issue**
   - If `config.mode === 'team'`:
     - Create issue with label from `config.github.labels.improvement`
     - Add link to Obsidian note in issue body
     - Add issue number to Obsidian note

## Image Handling

When user pastes an image or provides a path:

1. **Read the image** using the Read tool to verify it's valid
2. **Generate filename**: `improve-<slug>-<type>-<timestamp>.png`
   - Types: `before`, `after`, `diagram`, `benchmark`
3. **Copy to Obsidian attachments**:
   - Target: `<vault>/<project>/attachments/<filename>`
   - Use Bash: `cp "<source>" "<target>"`
4. **Reference in note**: `![[attachments/<filename>]]`

**Pasted images** appear as temporary files (e.g., `/var/folders/.../paste-XXX.png`).
The path is shown when user pastes - use that path to copy the file.

## After Implementation - Verification

When an improvement is completed:

**For performance improvements:**
- Ask: "Want to add an 'after' benchmark/screenshot?"
- Save as `improve-<slug>-after-<timestamp>.png`
- Show before/after comparison in the note

**For refactors:**
- Ask: "Want to add a screenshot of the new architecture?"
- Document the improvement visually

**For all categories:**
- Update note status to "completed"
- Add verification section with any screenshots

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

![[attachments/improve-<slug>-before-<timestamp>.png]]

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

### Before/After

<!-- Added after completion -->
| Before | After |
|--------|-------|
| ![[attachments/improve-<slug>-before.png]] | ![[attachments/improve-<slug>-after.png]] |

## Notes

<additional context>
```

## Category Guidelines

### Refactor
- No behavior change
- Tests should pass before and after
- Often enables future features
- Example: "Extract payment logic into PaymentService"
- **Images:** Architecture diagrams helpful

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
- **Images:** Before/after benchmarks critical

### Coverage
- Identify missing tests
- Focus on critical paths
- Don't test for coverage sake
- Example: "Add E2E tests for checkout flow"
- **Images:** Coverage reports helpful

## Configuration

From `.claw/config.json`:
- `mode`: 'solo' or 'team'
- `obsidian.vault`: path to vault
- `obsidian.project`: project folder in vault
- `github.labels.improvement`: label for improvement issues (team mode)
