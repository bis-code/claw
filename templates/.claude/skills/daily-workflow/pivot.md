# /pivot

Handle mid-day changes to the plan.

## What This Skill Does

Pivots are first-class citizens in the daily workflow. When plans change (and they will), this skill helps adapt gracefully while maintaining a record of decisions.

## Invocation

```
/pivot blocker      # Current issue is blocked by something
/pivot idea         # Better approach discovered
/pivot scope        # Issue is bigger or smaller than expected
/pivot urgent #123  # Add an urgent issue to today's plan
/pivot rethink      # AI suggests restructuring based on what it learned
```

---

## Blocker Flow

**When:** Something prevents completing the current issue.

### Steps

1. **Ask:** What's blocking? Is it resolvable today?

2. **If resolvable today:**
   - Add blocker resolution as a new task
   - Reorder plan to do blocker first
   - Log the pivot

3. **If not resolvable:**
   - Mark issue as `blocked` with reason
   - Add `blocked` label on GitHub
   - Comment on issue explaining the blocker
   - Move to tomorrow's candidates
   - Suggest next issue from today's plan

### Perspective Insights

Claude may offer:
- **Scrum Master**: "This blocker affects #45 and #46 too - escalate?"
- **CTO**: "This is a systemic issue - consider creating a tech debt ticket"

---

## Better Idea Flow

**When:** While working, you realize a smarter approach exists.

### Steps

1. **Ask:** Describe the better approach

2. **Evaluate:**
   - Does this change scope?
   - Does this affect other issues?
   - Should this become a pattern for similar issues?

3. **Update plan** with new approach

4. **Log the pivot** with reasoning

5. **Continue** with updated approach

### Perspective Insights

Claude may offer:
- **CTO**: "This pattern could apply to #45 and #47 too"
- **Product Owner**: "This approach better serves the user story"

---

## Scope Change Flow

**When:** Issue is bigger or smaller than the estimate.

### Steps

1. **Ask:** Bigger or smaller? By how much?

2. **If bigger:**
   - Can it be split? → Create sub-issues on GitHub
   - Should it move to tomorrow? → Defer with comment
   - Push through? → Update estimate, continue

3. **If smaller:**
   - Room for another issue today? → Suggest one
   - Pattern spotted? → Note for future estimation

### Perspective Insights

Claude may offer:
- **Scrum Master**: "Velocity data suggests splitting - you tend to finish more smaller items"
- **Product Owner**: "Core functionality is done - nice-to-haves can be a follow-up issue"

---

## Urgent Addition Flow

**When:** Something urgent needs to go into today's work.

### Steps

1. **Fetch issue details:**
   ```bash
   gh issue view 123
   ```

2. **Ask:** Replace something or add on top?

3. **If replace:**
   - Which issue to bump?
   - Move bumped issue to tomorrow
   - Comment explaining why

4. **Add urgent** to today's plan with priority

5. **Update state file**

### Perspective Insights

Claude may offer:
- **Sales**: "This is blocking the Acme deal - prioritize"
- **CEO**: "This aligns with our incident response SLA"

---

## AI Rethink Flow

**When:** Claude suggests restructuring based on patterns observed.

This can be triggered automatically during `/next` or `/done`, or manually via `/pivot rethink`.

### Triggers

Claude suggests restructuring when:
- Two remaining issues touch the same files
- A completed issue revealed something about remaining work
- Time remaining suggests reordering
- A pattern from a completed issue applies elsewhere

### Example

```
I noticed while completing #42:
- The BillingModal component I created would also help #45
- #47 uses similar Stripe patterns

Suggestion:
- Do #45 next (builds on #42 directly)
- Defer #48 to tomorrow (unrelated)
- #47 can reuse Stripe setup from #42

From a CTO perspective: This reduces code duplication.
From a Product perspective: #45 and #42 together complete the billing story.

Accept this restructuring? [y/n/modify]
```

---

## State File Updates

All pivots are logged in the daily file:

```markdown
## Pivots

### 10:45 - Scope Change
- issue: #42
- type: scope_increase
- reason: "3D Secure flow needed - wasn't in original spec"
- action: Added 1 hour, continuing today
- perspectives:
  - CTO: "Security requirement - non-negotiable"
  - Product: "Better user trust"

### 11:30 - AI Rethink (Accepted)
- type: restructure
- suggestion: "Combine #42 and #45 work - shared modal"
- accepted: true
- result: Created shared BillingModal.vue
- perspectives:
  - CTO: "Reduces duplication"
```

---

## GitHub Updates

| Pivot Type | GitHub Action |
|------------|---------------|
| Blocker | Add `blocked` label, comment with reason |
| Defer | Add `pivoted` label, comment with new date |
| Urgent | Add `in-progress` label, comment "Added to today's sprint" |
| Scope split | Create new issues, link to parent |
