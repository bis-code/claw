# Extended Thinking & Deep Reasoning

Claude Code supports **extended thinking** - allocating up to 31,999 tokens for internal reasoning before responding. This enables more thorough analysis, better tradeoff evaluation, and self-correction.

## When to Use Extended Thinking

Extended thinking is **mandatory** for:

### Planning & Architecture
- System design decisions
- Multi-service integration planning
- Database schema design
- API contract design
- Evaluating architectural patterns

### Complex Problem Solving
- Debugging intricate issues
- Performance optimization strategies
- Security vulnerability analysis
- Refactoring large codebases
- Dependency resolution

### Critical Decisions
- Technology selection
- Breaking changes
- Revenue-impacting features
- Data migration strategies
- Deployment strategies

### Multi-Step Workflows
- `/plan-day` - Daily work prioritization
- `/brainstorm` - Multi-agent planning
- `/auto-pilot` - Autonomous execution planning
- Feature implementation planning
- Test strategy design

## How to Trigger Extended Thinking

### In Skills (Automatic)

Skills that require deep reasoning include `ultrathink:` at the start of their internal prompts to automatically enable extended thinking.

**Example in skill prompt:**
```markdown
ultrathink: Analyze the daily issue queue and create an optimal execution plan...
```

### In User Messages (Manual)

Users can prefix requests with `ultrathink:` for comprehensive analysis:
```
ultrathink: design a caching layer for our API
ultrathink: how should we handle concurrent license activations?
```

### Global Configuration (Recommended)

For claw projects, enable extended thinking by default:

1. **Option 1: Environment Variable** (persistent)
   ```bash
   export MAX_THINKING_TOKENS=31999
   ```
   Add to `~/.bashrc` or `~/.zshrc`

2. **Option 2: Global Setting** (persistent)
   ```bash
   claude-code config set thinking.enabled true
   # Or via Claude Code: /config (toggle thinking mode on)
   ```

3. **Option 3: Session Toggle** (temporary)
   - Press `Option+T` (macOS) or `Alt+T` (Windows/Linux)

## Thinking Token Budget

| Mode | Thinking Tokens | Use Case |
|------|----------------|----------|
| **Disabled** | 0 | Simple, straightforward tasks |
| **Enabled** | 31,999 | Complex planning and problem-solving |
| **Custom** | Set via `MAX_THINKING_TOKENS` | Fine-tuned control |

**Important**: You are charged for all thinking tokens used.

## Viewing Internal Reasoning

Toggle verbose mode to see Claude's internal thinking process:
- **Keyboard**: `Ctrl+O` (shows gray italic reasoning text)
- **Purpose**: Understand how Claude reached conclusions, debug reasoning errors

## Integration with Operating Modes

Extended thinking integrates with claw's operating modes:

| Mode | Thinking Requirement |
|------|---------------------|
| **PLAN** | ✅ **Required** - Evaluate alternatives, identify risks |
| **IMPLEMENT** | Optional - Use for complex logic |
| **TEST** | Optional - Use for debugging test failures |
| **QA** | ✅ **Required** - Think through edge cases |
| **BUSINESS/PRODUCT** | ✅ **Required** - Evaluate user impact, business value |

## Lead-Level Reasoning Enhancement

Extended thinking enhances lead-level decision documentation:

```markdown
ultrathink: Analyze this feature request

## Deep Analysis Output:
Decision: [With comprehensive reasoning]
Why: [Multiple factors considered]
Trade-offs: [All evaluated]
When this breaks down: [Edge cases explored]

Alternatives Considered:
1. [Alternative A] — [Deep reasoning why not chosen]
2. [Alternative B] — [Conditions when preferable]
3. [Alternative C] — [Long-term implications]

Lead-Level Questions:
- What assumptions did we validate?
- What would a Staff+ engineer challenge?
- What future change makes this painful? (With scenarios)
- What would I warn the team about? (With mitigation strategies)
```

## Automatic Triggers in Claw

The following claw features automatically use extended thinking:

- **`/plan-day`** - Optimal issue prioritization
- **`/brainstorm`** - Multi-agent collaborative planning
- **`/auto-pilot`** - Discovery, prioritization, and execution planning
- **`/pivot`** - Evaluating scope changes and blockers
- **PR reviews** - Comprehensive code analysis
- **Architecture questions** - System design guidance

## Best Practices

### DO Use Extended Thinking When:
- Multiple valid approaches exist
- Decision has long-term consequences
- Security implications are present
- Performance is critical
- User experience is at stake
- Technical debt is being introduced
- Cross-service integration is involved

### DON'T Use Extended Thinking For:
- Simple CRUD operations
- Straightforward bug fixes
- Documentation updates
- Minor refactoring
- Tasks with clear, single solutions

## Verification

To verify extended thinking is enabled:
1. Check verbose mode (`Ctrl+O`) - you should see gray italic reasoning
2. Check token usage - thinking tokens should appear in output
3. Responses should show deeper analysis and more alternatives

## Relationship to Lead Reasoning

Extended thinking **amplifies** the lead reasoning rule:
- More alternatives explored
- Deeper tradeoff analysis
- Better edge case identification
- More thorough risk assessment

Think of it as:
- **Lead Reasoning**: The framework for what to analyze
- **Extended Thinking**: The cognitive capacity to analyze deeply

---

**TL;DR**: Enable extended thinking globally for claw projects to get comprehensive reasoning on all complex tasks. Skills automatically trigger it where needed.
