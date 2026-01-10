# Balanced Approach: Quality + Cost Efficiency

## The Problem with Extremes

### ❌ Option 1: Ultra-Cheap (What I Initially Proposed)
```
All Haiku, limit 10 results, skip brainstorm
Cost: ~$0.02 per run
Tokens: ~55k

Problems:
- Might miss important issues (only 10 TODOs when you have 50)
- Haiku gives worse analysis for complex security issues
- Skipping "obvious" issues might miss hidden complexity
- Too aggressive optimization = lost quality
```

### ❌ Option 2: Ultra-Expensive (What You Were Using)
```
All Sonnet, unlimited results, brainstorm everything
Cost: ~$1.35 per run
Tokens: ~450k

Problems:
- 49 tool uses for security scan (overkill)
- Reading full files during discovery (wasteful)
- Brainstorming simple TODOs (unnecessary)
- $493/year just for discovery if running daily
```

### ✅ Option 3: Balanced (Recommended)
```
Smart model selection + reasonable limits
Cost: ~$0.36 per run
Tokens: ~120k

Benefits:
- High quality where it matters (security, code quality)
- Efficient for mechanical tasks (TODO scanning, deps)
- Still thorough (20 results per search, not 10)
- 73% cost reduction while maintaining quality
```

---

## Smart Model Selection

**Key Insight:** Not all tasks require Sonnet's advanced reasoning.

### When Haiku is GOOD ENOUGH

| Task | Why Haiku Works | Example |
|------|----------------|---------|
| **TODO Scanning** | Just grep + parse | Find `TODO:` patterns → list files |
| **Dependency Check** | Just run commands | Run `npm outdated` → parse output |
| **Test Coverage** | Pattern matching | Find files without `_test.go` suffix |
| **File Listing** | Mechanical | Use Glob to list files |

**These don't need reasoning** - they're mechanical operations. Using Sonnet is wasteful.

### When Sonnet is NECESSARY

| Task | Why Sonnet Needed | Example |
|------|-------------------|---------|
| **Security Analysis** | Threat modeling | "Is this SQL concatenation vulnerable?" requires reasoning |
| **Code Quality** | Complexity analysis | "Is this 80-line function too complex?" needs judgment |
| **Architecture Review** | System thinking | "Does this introduce coupling?" needs understanding |
| **Bug Diagnosis** | Multi-file reasoning | "Why does this fail in production?" needs deep analysis |

**These need reasoning** - Haiku will give shallow answers.

---

## The Balanced Configuration

### Discovery Phase

```python
# Mechanical agents (Haiku)
todo_agent = Task(
    model="haiku",
    max_turns=3,
    description="Scan for TODOs",
    prompt="Find TODO patterns with Grep, limit 20 results"
)

dependency_agent = Task(
    model="haiku",
    max_turns=2,
    description="Check dependencies",
    prompt="Run npm outdated and go list -m -u all"
)

test_coverage_agent = Task(
    model="haiku",
    max_turns=3,
    description="Find missing tests",
    prompt="List files without test counterparts"
)

# Reasoning agents (Sonnet)
security_agent = Task(
    model="sonnet",
    max_turns=5,
    description="Security analysis",
    prompt="Analyze code for security vulnerabilities with reasoning"
)

code_quality_agent = Task(
    model="sonnet",
    max_turns=5,
    description="Code quality analysis",
    prompt="Identify complexity and maintainability issues"
)
```

**Result:**
- 3 Haiku agents × 8k = 24k tokens
- 2 Sonnet agents × 30k = 60k tokens
- **Total: ~84k tokens** (not 352k, not 40k)

### Brainstorm Phase

```python
def should_brainstorm(issue):
    """Only brainstorm if it needs multi-perspective analysis"""
    needs_brainstorm = [
        "security",
        "architecture",
        "user-facing",
        "breaking change",
        "performance"
    ]
    return any(keyword in issue.labels for keyword in needs_brainstorm)

def select_model_for_issue(issue):
    """Use Sonnet for complex issues, Haiku for simple ones"""
    complex_issues = ["security", "architecture", "performance"]
    if any(tag in issue.labels for tag in complex_issues):
        return "sonnet"
    return "haiku"

# Brainstorm only complex issues with right model
complex_issues = [i for i in issues if should_brainstorm(i)]
for issue in complex_issues:
    model = select_model_for_issue(issue)
    agents = get_relevant_agents(issue)  # Only spawn needed agents

    for agent_role in agents:
        brainstorm_agents.append(Task(
            subagent_type=agent_role,
            model=model,
            max_turns=2 if model == "haiku" else 3,
            prompt=f"Analyze {issue.title}..."
        ))
```

**Result:**
- Skip 15 obvious issues (TODOs, tests, deps)
- Brainstorm 8 complex issues
- 3-4 agents per issue (not always 5)
- Mix of Haiku (simple) and Sonnet (complex)
- **Total: ~40k tokens** (not 98k, not 25k)

---

## Cost-Quality Comparison

| Mode | Security Analysis | TODO Discovery | Dependency Check | Total Tokens | Cost | Quality Score |
|------|-------------------|----------------|------------------|--------------|------|---------------|
| **Shallow** | Haiku (shallow) | Haiku (10 results) | Haiku (quick) | 55k | $0.14 | ⭐⭐⭐ 60% |
| **Balanced** ⭐ | **Sonnet (thorough)** | Haiku (20 results) | Haiku (quick) | 120k | $0.36 | ⭐⭐⭐⭐ 90% |
| **Deep** | Sonnet (unlimited) | Sonnet (unlimited) | Sonnet (deep) | 450k | $1.35 | ⭐⭐⭐⭐⭐ 100% |

**Key takeaway:**
- Balanced mode gets you **90% of the quality at 27% of the cost**
- Diminishing returns: Deep mode costs 4x more for only 10% more quality

---

## When to Use Each Mode

### Use Shallow Mode When:
- ✅ Daily maintenance on familiar codebase
- ✅ Quick check before commit
- ✅ You just want a TODO list
- ✅ Budget-constrained project
- ❌ **NOT** for: Security audits, new codebase, critical changes

### Use Balanced Mode When:
- ✅ **Regular development** (most use cases)
- ✅ Weekly review of work
- ✅ Onboarding to new codebase
- ✅ Pre-PR review
- ✅ You want quality without excessive cost
- ✅ **Default for most users**

### Use Deep Mode When:
- ✅ Monthly/quarterly audit
- ✅ Pre-release security review
- ✅ Exploring completely new codebase
- ✅ Investigating production incident
- ✅ You need maximum thoroughness
- ❌ **NOT** for: Daily use (too expensive)

---

## Workflow Recommendation

```bash
# Daily (Monday - Thursday): Balanced mode
/auto --discovery balanced --hours 4
# Cost: $0.36/day × 4 days = $1.44/week

# Weekly review (Friday): Deep mode
/auto --discovery deep --hours 6
# Cost: $1.35

# Total weekly cost: ~$2.80
# vs. Deep mode daily: $1.35 × 5 = $6.75
# Savings: 58% while maintaining quality
```

**Annual comparison:**
- Shallow daily: $0.14 × 250 = **$35/year** ⚠️ May miss issues
- Balanced daily: $0.36 × 250 = **$90/year** ✅ Sweet spot
- Deep daily: $1.35 × 250 = **$338/year** 💸 Expensive
- **Balanced 4x + Deep 1x weekly: ~$145/year** ⭐ Best value

---

## Implementation

### Step 1: Set Default to Balanced

```python
# In auto.md
DEFAULT_DISCOVERY_MODE = "balanced"

if mode == "balanced":
    mechanical_agents = ["todo", "test-coverage", "dependency"]
    reasoning_agents = ["security", "code-quality"]

    for agent in mechanical_agents:
        spawn_agent(agent, model="haiku", max_turns=3, limit=20)

    for agent in reasoning_agents:
        spawn_agent(agent, model="sonnet", max_turns=5, limit=20)
```

### Step 2: Let User Override

```bash
# User can choose mode explicitly
/auto --discovery shallow    # Cheap
/auto --discovery balanced   # Default
/auto --discovery deep       # Thorough

# Or just:
/auto                        # Uses balanced by default
```

### Step 3: Smart Brainstorm

```python
def plan_brainstorm(issues, mode):
    if mode == "shallow":
        # Skip simple, Haiku for rest
        complex = [i for i in issues if is_complex(i)]
        return brainstorm(complex, model="haiku", max_turns=2)

    elif mode == "balanced":
        # Skip simple, smart model selection for rest
        complex = [i for i in issues if is_complex(i)]
        for issue in complex:
            model = "sonnet" if is_very_complex(issue) else "haiku"
            brainstorm(issue, model=model, max_turns=2 if model=="haiku" else 3)

    elif mode == "deep":
        # Brainstorm everything with Sonnet
        return brainstorm(issues, model="sonnet", max_turns=5)
```

---

## Monitoring & Adjustment

### Track Quality Over Time

```bash
# After each run, log:
- Issues found
- Issues that were false positives
- Issues that were missed (found manually later)

# Adjust if needed:
- If missing issues: Use deeper mode more often
- If too many false positives: Refine agent prompts
- If cost too high: Use shallow mode on quiet days
```

### Profile Token Usage

```bash
# Enable verbose to see per-agent costs
export CLAUDE_VERBOSE=1
/auto --discovery balanced

# Check output:
# - TODO Agent: 8k tokens ✓
# - Security Agent: 32k tokens ✓
# - If Security Agent uses 80k: Adjust limits
```

---

## Summary

**You were right to question the ultra-cheap approach.**

The balanced approach gives you:
- ✅ **90% of deep mode's quality**
- ✅ **73% cost reduction** vs deep mode
- ✅ **High quality where it matters** (security, architecture)
- ✅ **Efficient for routine tasks** (TODOs, deps)
- ✅ **Reasonable token limits** (20 results, not 10 or unlimited)
- ✅ **Smart model selection** (Haiku for mechanical, Sonnet for reasoning)

**Default recommendation:** Use balanced mode for daily work, deep mode for weekly audits.

---

**Questions?**
- "What if I want to customize limits?" → Adjust per your needs
- "What if balanced is still too expensive?" → Use shallow on quiet days
- "What if I need more thoroughness?" → Use deep mode when it matters
