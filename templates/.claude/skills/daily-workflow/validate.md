# /validate

**MANDATORY before marking any issue as done.**

This skill performs comprehensive validation to ensure a feature actually works, not just that tests pass.

## What This Skill Does

1. **Runs ALL relevant tests** (unit, integration, E2E)
2. **Validates configuration** (env vars, API keys, service connections)
3. **Tests user flows** (not just API endpoints)
4. **Checks edge cases** based on feature type
5. **Cross-service validation** (if feature spans services)

## Invocation

```
/validate              # Validate current issue
/validate --issue 14   # Validate specific issue
/validate --thorough   # Extra-thorough validation
```

---

## Validation Checklist by Feature Type

### Billing/Payment Features (`billing` label)

```
□ Configuration
  □ Run scripts/validate-stripe-config.sh
  □ Verify Stripe keys match between frontend/backend
  □ Check webhook endpoint is accessible

□ User Flows - MUST TEST ALL
  □ New user → checkout → subscription active
  □ Existing user → upgrade plan
  □ Existing user → downgrade plan
  □ Active subscription → cancel → grace period
  □ Cancelled subscription → renew/reactivate
  □ Update payment method
  □ View invoices

□ Edge Cases
  □ What shows after cancellation?
  □ Can user resubscribe after cancel?
  □ What happens when payment fails?
  □ Is license still valid during grace period?

□ E2E Tests
  □ All billing.spec.ts tests pass
  □ No Stripe console errors
  □ Stripe Elements loads successfully
```

### License Features (`license` label)

```
□ Configuration
  □ Ed25519 keys are configured
  □ License service is reachable

□ User Flows - MUST TEST ALL
  □ Generate new license
  □ Activate license on desktop
  □ Validate license key
  □ Deactivate license
  □ Re-activate on different machine

□ Edge Cases
  □ What happens when max activations reached?
  □ What happens when license expires?
  □ What happens when license is cancelled?
  □ What happens when subscription is cancelled but not expired?
  □ Does heartbeat still work after cancellation?

□ Cross-Service Testing
  □ Portal shows correct license state
  □ Desktop app can activate
  □ Desktop app validates on heartbeat
```

### Authentication Features (`auth` label)

```
□ User Flows - MUST TEST ALL
  □ Register new user
  □ Login existing user
  □ Logout
  □ Password reset
  □ Token refresh

□ Edge Cases
  □ Invalid credentials
  □ Expired token
  □ Concurrent sessions
```

### API Features (`api` label)

```
□ Test ALL affected endpoints
  □ Happy path
  □ Error cases (400, 401, 404, 500)
  □ Input validation
  □ Authorization checks

□ Documentation
  □ API changes documented
```

---

## Validation Agent Process

When `/validate` is invoked:

### Step 1: Identify Feature Type

```bash
# Get labels from current issue
gh issue view $ISSUE_NUMBER --json labels
```

### Step 2: Run Configuration Checks

```bash
# Always run these
./scripts/validate-stripe-config.sh  # If billing-related

# Check services are running
curl -s http://localhost:8086/health  # license-api
curl -s http://localhost:8087         # license-portal
```

### Step 3: Run Test Suites

```bash
# Backend tests
cd apps/license-api && go test ./... -v

# Frontend tests
cd apps/license-portal && npm run test:run

# E2E tests for the feature
cd apps/license-portal && npx playwright test [relevant].spec.ts
```

### Step 4: Test User Flows

**This is where we failed today.** The agent MUST actually test:

```
For billing features:
1. Open browser at localhost:8087
2. Login as test user
3. Navigate to Dashboard
4. Test each button/flow in the checklist
5. Verify console has no errors
6. Verify UI shows correct state
```

### Step 5: Report Results

```markdown
## Validation Report for #14

### Configuration ✅
- [x] Stripe keys match
- [x] Services running

### User Flows
- [x] Checkout flow works
- [x] Cancel subscription works
- [ ] ❌ Renew after cancel - Button not available!
- [x] Update payment method - Shows 400 error ❌

### Edge Cases
- [ ] ❌ License invalid after cancel

### Verdict: NOT READY
Issues found: 3

Created:
- #17 - Cannot resubscribe after cancel
- #18 - License invalid after cancel
```

---

## Blocking Behavior

**CRITICAL:** `/done` CANNOT be called until `/validate` passes.

If validation fails:
1. Create GitHub issues for each failure
2. Link failures to original issue
3. DO NOT close the original issue
4. Report what needs to be fixed

---

## Manual Testing Requirements

Some things cannot be fully automated. For these, the agent MUST:

1. **Actually navigate the UI** (via E2E tests or describe what to test)
2. **Check browser console** for errors
3. **Test the full user journey**, not just individual endpoints
4. **Verify visual state** matches expected state

---

## Integration with /done

```
User: /done

Claude: Running /validate first...

[Validation runs]

If PASS:
  Claude: ✅ Validation passed. Marking #14 as done.

If FAIL:
  Claude: ❌ Validation failed. Cannot mark as done.

  Issues found:
  - Renew button not showing after cancel
  - License key invalid after cancel

  Created issues #17, #18 for these problems.

  Fix these issues or use /done --force to override.
```

---

## Override (Use With Caution)

```
/done --force --reason "Known issue, will fix in next sprint"
```

This bypasses validation but:
1. Logs the override reason
2. Creates follow-up issues automatically
3. Adds warning to PR description
