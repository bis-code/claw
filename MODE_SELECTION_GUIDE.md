# Mode Selection Guide for /auto

Quick reference for choosing the right discovery mode.

---

## Interactive Prompt (Default)

When you run `/auto`, you'll see:

```
🔍 Discovery Mode

Choose discovery depth for this session:

1. Shallow - Fast & cheap (~55k tokens, $0.14)
   ✓ Quick daily scan, familiar codebase
   ✗ May miss deep issues

2. Balanced - Smart mix (~120k tokens, $0.36) ⭐ Recommended
   ✓ High quality where it matters
   ✓ Efficient for routine tasks
   ✓ Good for regular development

3. Deep - Thorough audit (~450k tokens, $1.35)
   ✓ Maximum thoroughness
   ✓ Weekly/monthly audit
   ✗ Expensive for daily use

Select [1-3] (default: 2): _
```

---

## Quick Decision Tree

```
Are you doing a security audit or exploring new code?
    ├─ YES → Deep mode
    └─ NO  ↓

Is this a familiar codebase you work on daily?
    ├─ YES → Balanced mode (or Shallow if just checking TODOs)
    └─ NO  ↓

Do you need thorough analysis?
    ├─ YES → Balanced mode
    └─ NO  → Shallow mode
```

---

## Mode Comparison Table

| Aspect | Shallow | Balanced ⭐ | Deep |
|--------|---------|------------|------|
| **Cost** | $0.14 | $0.36 | $1.35 |
| **Tokens** | ~55k | ~120k | ~450k |
| **Time** | Fast (5-10 min) | Medium (10-20 min) | Slow (20-40 min) |
| **TODO scanning** | ✓ Good (Haiku) | ✓ Good (Haiku) | ✓✓ Excellent (Sonnet) |
| **Security analysis** | ⚠️ Basic (Haiku) | ✓ Good (Sonnet) | ✓✓ Thorough (Sonnet) |
| **Code quality** | ⚠️ Surface-level (Haiku) | ✓ Good (Sonnet) | ✓✓ Deep (Sonnet) |
| **Result limit** | 10 per search | 20 per search | Unlimited |
| **Brainstorm** | Skip simple issues | Smart selection | All issues |
| **Best for** | Quick daily check | Regular development | Weekly audit |

---

## When to Use Each Mode

### 🏃 Shallow Mode - Use When:

```
✓ Daily morning check
✓ Quick pre-commit scan
✓ Just want a TODO list
✓ Working on familiar codebase
✓ Time-constrained
✓ Budget-conscious project

Example:
  "Quick check before I start coding today"
  "Any TODOs I forgot about?"
```

**What you get:**
- All TODOs, FIXMEs found
- Missing tests identified
- Outdated dependencies listed
- Basic security patterns checked
- Surface-level code quality

**What you might miss:**
- Subtle security vulnerabilities
- Complex code quality issues
- Edge cases
- Deep architectural problems

---

### ⚖️ Balanced Mode - Use When:

```
✓ Regular daily/weekly development
✓ Pre-PR review
✓ Feature development session
✓ Onboarding to codebase
✓ Want quality + reasonable cost
✓ DEFAULT for most users

Example:
  "Let's see what needs work today"
  "Planning my sprint"
  "What should I prioritize?"
```

**What you get:**
- All TODOs, FIXMEs found (Haiku)
- Missing tests identified (Haiku)
- Outdated dependencies listed (Haiku)
- **Thorough security analysis (Sonnet)**
- **Deep code quality review (Sonnet)**
- Smart brainstorming (Sonnet for complex issues)

**What you might miss:**
- Very rare edge cases
- Extremely subtle patterns

**This is the sweet spot** - 90% of deep mode's quality at 27% of the cost.

---

### 🔍 Deep Mode - Use When:

```
✓ Weekly/monthly audit
✓ Pre-release review
✓ Security audit required
✓ Exploring new codebase
✓ Investigating production issues
✓ Need maximum confidence

Example:
  "Full security audit before release"
  "First time exploring this codebase"
  "Monthly code health review"
```

**What you get:**
- Everything from Balanced mode
- **Unlimited search results** (not capped at 20)
- **Extended exploration** (max_turns: 10)
- **All issues brainstormed** (not just complex)
- **ultrathink enabled** for deepest reasoning
- Maximum thoroughness possible

**Tradeoff:**
- 4x more expensive than Balanced
- 3-4x slower
- Only 10% more thorough than Balanced

**Use sparingly** - not for daily work.

---

## Skip the Prompt

If you know what you want:

```bash
# Morning check
/auto --discovery shallow

# Regular development (most days)
/auto --discovery balanced

# Friday audit
/auto --discovery deep

# Just use existing issues
/auto --skip-discovery
```

---

## Recommended Weekly Pattern

```
Monday:    /auto --discovery balanced --hours 6
Tuesday:   /auto --discovery balanced --hours 6
Wednesday: /auto --discovery balanced --hours 6
Thursday:  /auto --discovery shallow --hours 4   # Quick check
Friday:    /auto --discovery deep --hours 8      # Weekly audit

Weekly cost: ($0.36 × 3) + $0.14 + $1.35 = $2.57
vs. Deep daily: $1.35 × 5 = $6.75
Savings: 62%
```

---

## FAQ

### Q: What if Balanced is still too expensive for me?

**A:** Use Shallow for daily work, Balanced once a week:
```
Mon-Thu: /auto --discovery shallow  ($0.14 × 4 = $0.56)
Friday:  /auto --discovery balanced ($0.36)
Weekly:  $0.92 (vs $1.80 balanced daily)
```

### Q: What if I want even more thoroughness than Deep?

**A:** You can:
1. Use Deep mode with extended hours: `/auto --discovery deep --hours 12`
2. Run multiple passes with different focuses: `/auto --discovery deep --focus "security"`
3. Combine with manual review

### Q: Can I set a default mode?

**A:** Yes! In `.claude/settings.json`:
```json
{
  "auto": {
    "default_discovery_mode": "balanced",
    "skip_mode_prompt": false
  }
}
```

### Q: How do I know if I'm missing issues with Shallow?

**A:** Periodically run Deep mode and compare:
```bash
# Monday: Shallow
/auto --discovery shallow

# Friday: Deep (compare findings)
/auto --discovery deep

# If Deep finds significantly more: Use Balanced daily
```

### Q: Does the mode affect execution quality?

**A:** No! The mode only affects **discovery and brainstorm**. Once execution starts, it uses Sonnet for implementation regardless of mode.

---

## Summary

**For 90% of users:**
- Use `/auto` (prompts for mode, defaults to Balanced)
- Or: `/auto --discovery balanced` (skip prompt)

**If you want to save money:**
- Use Shallow daily, Balanced weekly

**If you want maximum quality:**
- Use Balanced daily, Deep weekly

**Default recommendation:** Balanced mode, let it prompt you so you make conscious choice each time.
