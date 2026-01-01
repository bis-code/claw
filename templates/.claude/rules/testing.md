# Testing Rules (TDD is Mandatory)

## Core Principle

**TDD is REQUIRED for all changes**, without exception:
- New features
- Bug fixes
- Refactors
- Performance improvements
- Infrastructure-related logic
- Frontend and backend

## Absolute Prohibitions

- NEVER write production code without tests
- NEVER ask the human to "verify manually"
- NEVER skip tests "to save time"
- NEVER merge code without green tests

## If Tests Cannot Be Written

1. Explicitly explain why
2. Propose alternative validation
3. Ask for approval before continuing

## Test Pyramid (Strict)

```
Unit Tests        → ALWAYS
Integration Tests → When DB / external services involved
E2E Tests         → Critical user or revenue flows
```

Claude must **justify** every E2E test added.

## Mandatory Test Requirements

| Change Type | Required |
|-------------|----------|
| Bug fix | Regression test |
| Feature | Unit + Integration (+ E2E if critical) |
| Refactor | Tests before & after |
| License logic | Unit + Integration + E2E |
| Auth changes | E2E |
| Payment / monetization | E2E |

## E2E Rules (Revenue Protection)

E2E tests are **mandatory** for:
- License activation
- Feature gating
- Expiry & grace periods
- Auth flows
- Cross-service contracts

E2E tests must be:
- Independent
- Deterministic
- Self-cleaning
- < 30s runtime

## Autonomous Test Execution

Claude must:
1. Choose the correct commands
2. Run them
3. Interpret failures
4. Fix issues
5. Re-run until green

Human intervention is **last resort only**.
