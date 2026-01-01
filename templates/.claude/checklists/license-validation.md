# License Feature Validation Checklist

**Use this checklist before marking ANY license-related issue as complete.**

## Pre-Flight Checks

- [ ] Verify license-api is running: `curl http://localhost:8086/health`
- [ ] Verify highlights-api is running (if desktop features): `curl http://localhost:8085/health`
- [ ] Verify Ed25519 keys are configured

## Test Suite Requirements

- [ ] Backend tests pass: `cd apps/license-api && go test ./... -v`
- [ ] Desktop tests pass (if applicable): `cd apps/highlights-desktop && npm test`
- [ ] E2E tests pass

## User Flow Testing (MANDATORY)

### 1. License Generation
- [ ] Create new user
- [ ] Complete checkout for paid plan
- [ ] Verify license key is generated
- [ ] Verify license key format is correct (VH-XXXX-...)
- [ ] Verify license appears in dashboard

### 2. License Activation (Desktop)
- [ ] Open desktop app
- [ ] Enter license key
- [ ] Verify activation succeeds
- [ ] Verify activation count increases (0/1 → 1/1)
- [ ] Verify features unlock

### 3. License Validation
- [ ] Make API call to validate endpoint
- [ ] Verify active license returns valid
- [ ] Verify response includes product features
- [ ] Verify heartbeat endpoint works

### 4. License Deactivation
- [ ] Deactivate from desktop app
- [ ] Verify activation count decreases
- [ ] Verify can reactivate on same or different machine

### 5. License States (Critical!)

Test each state and verify correct behavior:

| State | Portal Shows | Desktop Activation | Validation API |
|-------|--------------|-------------------|----------------|
| Active subscription | ✅ Active | ✅ Works | ✅ Valid |
| Cancelled (grace period) | ⚠️ Cancelled, expires [date] | ✅ Works | ✅ Valid |
| Expired | ❌ Expired | ❌ Fails | ❌ Invalid |
| Revoked | ❌ Revoked | ❌ Fails | ❌ Invalid |

- [ ] Active subscription → works everywhere
- [ ] Cancelled but in grace period → STILL WORKS (this is often broken!)
- [ ] Expired → correctly rejected
- [ ] Revoked → correctly rejected

### 6. Max Activations
- [ ] Activate on machine 1
- [ ] Activate on machine 2 (if limit allows)
- [ ] Try to exceed limit
- [ ] Verify helpful error message
- [ ] Verify deactivation frees slot

## Cross-Service Testing

- [ ] Portal license status matches API response
- [ ] Desktop app state matches portal
- [ ] Webhook updates propagate correctly

## Edge Cases

- [ ] What happens when activating invalid key?
- [ ] What happens when activating revoked key?
- [ ] What happens when subscription payment fails?
- [ ] What happens on network timeout during activation?
- [ ] Does offline grace period work?

## Final Verification

- [ ] All above items checked
- [ ] Created issues for any failures found
- [ ] Ready to mark issue as done

---

**If ANY item fails, DO NOT mark the issue as complete. Create a new issue for the failure.**
