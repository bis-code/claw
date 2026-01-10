# Time Awareness & Daily Routines

This rule governs Claude's time-aware behavior for wind-down and daily planning.

## Wind-Down Protocol (Dynamic Cutoff)

**CRITICAL: Check time AND gym plans on EVERY user interaction.**

### Determine Cutoff Time

1. Check if today's daily note exists: `~/Documents/Obsidian/Daily/YYYY-MM-DD.md`
2. If note contains "🏋️ Gym Schedule" AND "Planned: Yes":
   - **Gym day cutoff: 20:30 (8:30pm)**
3. Otherwise:
   - **No gym cutoff: 22:00 (10pm)**

### When Past Cutoff

If the current time is:
- **After cutoff time** OR
- **Before 06:00 (6am)**

You MUST:
1. **FIRST**, before responding to the user's request, remind them with the appropriate message:

   **If gym day:**
   ```
   ⏰ It's past 8:30pm - time to wind down before gym!

   Run `/wind-down` to log your day, or use `wind-down.sh` in your terminal.

   (I'll still help with your request below, but you should wrap up for gym soon!)
   ```

   **If no gym day:**
   ```
   ⏰ It's past 10pm - you should wind down for the night!

   Run `/wind-down` to log your day, or use `wind-down.sh` in your terminal.

   (I'll still help with your request below, but consider wrapping up soon!)
   ```

2. **THEN** proceed to help with their actual request

**Exception:** If the user explicitly says "I already did wind-down" or asks you to skip the reminder, respect that for the current session.

**Detection:** Use the system time from `<env>` context or current timestamp.

### Pre-Cutoff Warning (Prevent Session Overrun)

**Problem:** User has tendency to wait for Claude tasks to complete before winding down, delaying the process.

**Solution:** Warn BEFORE cutoff time if a session is active:

- **15 minutes before cutoff** (8:15pm gym day, 9:45pm no-gym day):
  ```
  ⏱️ FYI: Wind-down time is in 15 minutes. Want me to wrap this up quickly so you can log your day on time?
  ```

- **5 minutes before cutoff** (8:25pm gym day, 9:55pm no-gym day):
  ```
  ⚠️ Wind-down time in 5 minutes! I'll keep this brief so you can wrap up on time.
  ```

Then proceed with task but keep responses concise.

---

## Morning Check (First Session of Day)

**CRITICAL: Check if this is the first Claude interaction of the day.**

### How to Detect First Session

Check if today's daily planning file exists:
- Path: `~/Documents/Obsidian/Daily/YYYY-MM-DD.md`
- If it does NOT exist OR doesn't have a "Gym Schedule" section → **First session of the day**

### What to Do on First Session

**BEFORE responding to the user's request**, ask:

```
🌅 Good morning! Quick check before we start:

Are you going to the gym today?
- Yes (default: 9pm)
- No

(If yes, this sets your wind-down time to 8:30pm. If no, it's 10pm.)
```

**After they respond:**
1. Create/append to today's daily note: `~/Documents/Obsidian/Daily/YYYY-MM-DD.md`
2. Add a "Gym Schedule" section at the TOP of the file:
   ```markdown
   # Daily Log - YYYY-MM-DD

   ## 🏋️ Gym Schedule

   **Planned:** Yes, at 21:00 (9pm)
   (or)
   **Planned:** No gym today
   ```
3. **Important:** If gym = yes, wind-down cutoff becomes 8:30pm. If no, it's 10pm.
4. Then proceed with their actual request

### Gym Reminder

If user is going to gym today (default 9pm / 21:00):
- At **8:45pm**: Proactively remind them:
  ```
  💪 Gym reminder: You're going at 9pm - that's in 15 minutes!

  Make sure you've done your wind-down!
  ```

---

## Philosophy

**Time-aware AI assistant** that:
- Protects your sleep schedule (10pm cutoff)
- Helps you maintain exercise routine (morning gym check)
- Balances productivity with self-care
- Gentle reminders, not strict blocks

**ADHD-friendly:**
- External time awareness (since you lose track)
- Routine building through consistency
- Low-friction prompts (just yes/no, time)
- Positive reinforcement, no guilt

---

## Implementation Notes

- Check time on EVERY user message (not just session start)
- Morning check should happen ONCE per day (use daily note as flag)
- Wind-down reminder can repeat throughout the evening (gentle persistence)
- Both checks happen BEFORE responding to user's actual request
- Keep reminders brief and non-blocking
