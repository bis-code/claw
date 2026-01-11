# Quick Token Optimization Fixes

> **✅ IMPLEMENTED:** These optimizations are now built into `/auto` with three modes:
> - `--discovery shallow` (~55k tokens)
> - `--discovery balanced` (~120k tokens) - Default
> - `--discovery deep` (~450k tokens)
>
> This document is kept for reference showing the optimization journey.

---

Your `/auto` was using **450k tokens** for discovery + brainstorm. Here's how to reduce it to **~60k tokens (85% reduction)** with 5 simple changes.

---

## Your Problem

```
Discovery Phase:  352k tokens
├─ TODO Scanner:    66.7k (44 tool uses)
├─ Test Coverage:   72.7k (39 tool uses)
├─ Code Quality:    89.7k (33 tool uses)
├─ Security Scan:   93.5k (49 tool uses!) ← MOST EXPENSIVE
└─ Dependency:      29.9k (26 tool uses)

Brainstorm Phase:  98k tokens
├─ 5 agents × ~20k each

TOTAL: ~450k tokens before writing any code!
Cost: ~$1.35 per run (at Claude API pricing)
```

---

## 5 Quick Fixes (Copy-Paste Ready)

### Fix #1: Use Haiku for Discovery (70% reduction)

**When spawning discovery agents**, add `model="haiku"`:

```python
# ❌ Before (expensive)
Task(
    subagent_type="Explore",
    description="Scan for TODOs",
    prompt="Find all TODOs..."
)

# ✅ After (cheap)
Task(
    subagent_type="Explore",
    model="haiku",  # ← ADD THIS LINE
    description="Scan for TODOs",
    prompt="Find all TODOs..."
)
```

**Impact:** 66.7k → ~8k tokens per agent
**Savings:** ~58k tokens per discovery agent

---

### Fix #2: Limit Tool Uses with max_turns

**Add max_turns to prevent runaway exploration**:

```python
# ❌ Before (49 tool uses!)
Task(
    subagent_type="Explore",
    model="haiku",
    prompt="Scan for security issues..."
)

# ✅ After (limited to ~10-15 tool uses)
Task(
    subagent_type="Explore",
    model="haiku",
    max_turns=3,  # ← ADD THIS LINE (max 3 rounds)
    prompt="Scan for security issues..."
)
```

**Impact:** 49 tool uses → ~12 tool uses
**Savings:** ~50k tokens on security agent alone

---

### Fix #3: Limit Search Results with head_limit

**In discovery agent prompts**, add Grep constraints:

```markdown
# ❌ Before (returns everything)
ultrathink: Find all TODOs in the codebase.

Use Grep to search for TODO patterns.

# ✅ After (top 10 only)
ultrathink: Find all TODOs in the codebase.

CRITICAL CONSTRAINTS:
- Use Grep with head_limit: 10 (max 10 results)
- Use output_mode: "files_with_matches" (just file names, not content)
- Do NOT read full file contents during discovery
- Stop after finding 10 issues
```

**Impact:** Unlimited results → 10 results
**Savings:** ~20-30k tokens per agent

---

### Fix #4: Skip Brainstorm for Obvious Issues

**Before brainstorming**, filter out simple issues:

```python
# ❌ Before (brainstorm everything)
brainstorm_issues = all_discovered_issues  # 23 issues

# ✅ After (brainstorm only complex issues)
def should_brainstorm(issue):
    """Skip brainstorm for obvious issues"""
    obvious_patterns = [
        "TODO:",
        "FIXME:",
        "Add test for",
        "Update dependency",
        "Fix typo"
    ]
    return not any(pattern in issue.title for pattern in obvious_patterns)

complex_issues = [i for i in all_discovered_issues if should_brainstorm(i)]
brainstorm_issues = complex_issues  # ~5-8 issues
```

**Impact:** 23 issues → 8 complex issues
**Savings:** ~60k tokens (skipping 15 obvious issues)

---

### Fix #5: Use Haiku for Brainstorm Too

**When spawning brainstorm agents**, add `model="haiku"` and `max_turns`:

```python
# ❌ Before (expensive)
agents = []
for role in ["senior-dev", "product", "cto", "qa", "ux"]:
    agents.append(Task(
        subagent_type=role,
        prompt=f"Analyze these {len(issues)} issues..."
    ))

# ✅ After (cheap)
agents = []
# Only spawn agents needed for this type of work
roles = ["senior-dev", "cto", "qa"]  # Skip product & ux for technical issues
for role in roles:
    agents.append(Task(
        subagent_type=role,
        model="haiku",   # ← ADD THIS
        max_turns=2,     # ← ADD THIS
        prompt=f"Analyze these {len(complex_issues)} complex issues..."
    ))
```

**Impact:** 98k → ~25k tokens
**Savings:** ~73k tokens

---

## Results After Fixes

```
Discovery Phase: 38k tokens (was 352k)
├─ TODO Scanner:     8k (was 66.7k) ✅
├─ Test Coverage:    8k (was 72.7k) ✅
├─ Code Quality:     8k (was 89.7k) ✅
├─ Security Scan:   10k (was 93.5k) ✅
└─ Dependency:       4k (was 29.9k) ✅

Brainstorm Phase: 25k tokens (was 98k)
├─ 3 agents × ~8k each (was 5 agents × 20k)

TOTAL: ~63k tokens (was 450k)
Reduction: 85% 🎉
Cost: ~$0.02 per run (was $1.35)
```

---

## How to Test

### 1. Update Your Discovery Agents

Find where you spawn discovery agents and add:
```python
model="haiku",
max_turns=3
```

### 2. Update Agent Prompts

Add these constraints to all discovery prompts:
```
CRITICAL CONSTRAINTS:
- Use Grep with head_limit: 10
- Use files_with_matches mode
- Do NOT read full files
```

### 3. Filter Before Brainstorm

Add this function before brainstorming:
```python
def should_brainstorm(issue):
    obvious = ["TODO:", "FIXME:", "Add test", "Update dep"]
    return not any(p in issue.title for p in obvious)
```

### 4. Update Brainstorm Agents

Add to all brainstorm agent calls:
```python
model="haiku",
max_turns=2
```

### 5. Run Test

```bash
cd your-project
claude

# Test with verbose to see token counts
/auto --plan-only

# Check output (ctrl+o to expand)
# Should see much lower token counts per agent
```

---

## Verification Checklist

After implementing fixes, verify:

- [ ] Discovery agents show `model: haiku` in output
- [ ] Each discovery agent uses <15k tokens (was 60-90k)
- [ ] Search results limited to 10 items max
- [ ] Only 5-8 complex issues go to brainstorm (not 23)
- [ ] Brainstorm agents show `model: haiku`
- [ ] Each brainstorm agent uses <10k tokens (was 20k)
- [ ] Total discovery + brainstorm < 100k tokens (was 450k)

---

## Expected Impact

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Discovery tokens** | 352k | ~38k | **90% reduction** |
| **Brainstorm tokens** | 98k | ~25k | **75% reduction** |
| **Total tokens** | 450k | ~63k | **86% reduction** |
| **Cost per run** | $1.35 | $0.02 | **98% cheaper** |
| **Annual cost (daily)** | $493 | $7 | **$486 saved** |

---

## Troubleshooting

### "My agents still use 60k+ tokens"

Check:
1. Did you add `model="haiku"` to **all** discovery agents?
2. Did you add `max_turns=3` to limit exploration?
3. Did you add `head_limit: 10` in the agent prompts?

### "Brainstorm still costs 80k+ tokens"

Check:
1. Are you filtering out obvious issues before brainstorm?
2. Did you add `model="haiku"` to **all** brainstorm agents?
3. Did you add `max_turns=2` to limit debate rounds?
4. Are you using 5 agents when 3 would do?

### "Discovery finds fewer issues now"

**This is expected!** You're limiting to 10 results per search. Options:
- Increase `head_limit: 20` (but still cap it)
- Run discovery twice with different focuses
- Use `--discovery deep` flag for thorough scan (when needed)

---

## Next Steps

1. ✅ Implement the 5 fixes above
2. ✅ Test with `/auto --plan-only`
3. ✅ Verify token counts in output (ctrl+o)
4. ✅ Adjust limits based on your needs
5. ✅ Read full guide: `docs/TOKEN_OPTIMIZATION.md`

---

**Questions?** Check `docs/TOKEN_OPTIMIZATION.md` for detailed explanations and examples.
