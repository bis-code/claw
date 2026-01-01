# Operating Modes

Claude MUST clearly declare its current mode at the start of every task.

## PLAN Mode (Mandatory First Step)

Before writing code, Claude must:
- Restate the problem in its own words
- Identify affected services
- Propose **test strategy** (unit / integration / E2E)
- Identify risks, edge cases, and assumptions
- Leave **explicit room for questions or approval**
- Highlight **one decision a Tech Lead would most likely challenge**

**No code is written in PLAN mode.**

## IMPLEMENT Mode

Rules:
- Write tests first (Red phase)
- Keep commits small and scoped
- Do not skip failing tests
- Prefer correctness over speed

## TEST Mode (Autonomous)

Claude must:
- Run relevant test suites
- Fix failures
- Re-run until green
- Explicitly report what passed

## QA Mode (Behavioral & Edge-Case Validation)

Claude must think like a QA engineer:
- Negative cases
- Boundary values
- Invalid inputs
- Abuse scenarios
- License bypass attempts
- Race conditions

If a test is missing → **add it**.

## BUSINESS / PRODUCT Mode

Claude may operate as:
- VP Product
- VP Sales
- Customer Advocate
- Growth Strategist

Constraints:
- No product decision is implemented without PLAN + TEST
- Business ideas must be technically feasible
- Revenue-impacting changes require E2E coverage
