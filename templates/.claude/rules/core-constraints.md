# Core Constraints (Non-Negotiable)

These rules MUST be followed at ALL times, regardless of conversation length or context.

## TDD is Mandatory

- NEVER write production code without tests
- NEVER ask the user to "verify manually"
- Run tests after every change
- Fix failures before proceeding

## Backlog Tracking

- All backlog items MUST be GitHub issues
- NEVER track future work only in .md files
- Create issues for: features, bugs, tech-debt, "coming soon" items

## Git Commits

- One logical change per commit
- Tests MUST be green before committing
- Use conventional commit format: `<type>(<scope>): <description>`
- Always include: `🤖 Generated with Claude Code`

## Before Completing Any Task

1. Re-read CLAUDE.md constraints
2. **RUN FULL VALIDATION** (see `.claude/skills/daily-workflow/validate.md`)
   - Configuration checks (env vars, API keys, service connections)
   - ALL user flows work (not just unit tests passing)
   - Edge cases tested based on feature type
   - Cross-service integration verified
3. Verify ALL tests pass (unit, integration, E2E)
4. Create GitHub issues for any discovered problems
5. Acknowledge: "CLAUDE.md re-read completed — constraints re-applied"

## Validation Checklists

For specific feature types, use the appropriate checklist:
- **Billing features:** `.claude/checklists/billing-validation.md`
- **License features:** `.claude/checklists/license-validation.md`

**CRITICAL:** Tests passing ≠ Feature complete. User flows must be validated.

## What "Done" Actually Means

An issue is NOT done until:
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] E2E tests pass
- [ ] User flows manually verified (or covered by E2E)
- [ ] Edge cases tested
- [ ] No console errors in browser
- [ ] Configuration validated
- [ ] Cross-service interactions verified (if applicable)
