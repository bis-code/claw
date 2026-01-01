# Billing Feature Validation Checklist

**Use this checklist before marking ANY billing-related issue as complete.**

## Pre-Flight Checks

- [ ] Run `./scripts/validate-stripe-config.sh`
- [ ] Verify license-api is running: `curl http://localhost:8086/health`
- [ ] Verify license-portal is running: `curl http://localhost:8087`
- [ ] Check browser console is clear of errors

## Test Suite Requirements

- [ ] Backend tests pass: `cd apps/license-api && go test ./... -v`
- [ ] Frontend tests pass: `cd apps/license-portal && npm run test:run`
- [ ] E2E tests pass: `cd apps/license-portal && npx playwright test billing.spec.ts`

## User Flow Testing (MANDATORY)

### 1. New User Journey
- [ ] Register new user
- [ ] View plans (should show all tiers)
- [ ] Select paid plan → Checkout modal opens
- [ ] Stripe Elements loads without errors
- [ ] Complete checkout (use test card 4242...)
- [ ] Verify subscription is active
- [ ] Verify license key is generated

### 2. Manage Subscription
- [ ] Click "Manage Subscription"
- [ ] View current plan details
- [ ] "Update Payment Method" opens modal
- [ ] Stripe Elements loads in modal
- [ ] "View Invoices" opens modal with invoice list
- [ ] "Cancel Subscription" opens confirmation modal

### 3. Cancel Flow
- [ ] Cancel subscription
- [ ] Verify success message shows period end date
- [ ] Verify dashboard shows "Cancelled" state
- [ ] Verify "Renew" button appears (not "Cancel")
- [ ] Verify license is still valid during grace period

### 4. Renewal Flow (Often Forgotten!)
- [ ] After cancellation, click "Renew"
- [ ] Verify subscription is reactivated
- [ ] Verify "Cancel" button returns
- [ ] Verify license continues working

### 5. Desktop App Integration
- [ ] Copy license key from portal
- [ ] Paste in desktop app activation
- [ ] Verify activation succeeds
- [ ] Verify heartbeat works
- [ ] Cancel subscription in portal
- [ ] Verify desktop app still works (grace period)

## Edge Cases

- [ ] What happens if user already has subscription? (shows appropriate message)
- [ ] What happens on payment failure? (shows error, doesn't create license)
- [ ] What shows for Enterprise tier? (Contact Sales / Coming Soon)
- [ ] Can user switch between monthly/yearly?

## Console Error Check

Open browser DevTools during all above tests and verify:
- [ ] No 400 errors from Stripe
- [ ] No "loaderror" events
- [ ] No unhandled promise rejections
- [ ] No CORS errors

## Final Verification

- [ ] All above items checked
- [ ] Created issues for any failures found
- [ ] Ready to mark issue as done

---

**If ANY item fails, DO NOT mark the issue as complete. Create a new issue for the failure.**
