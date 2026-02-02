# /claw-run

Execute work items autonomously with verification and feedback loops.

## Usage

```
/claw-run                    # Interactive: select items, work with check-ins
/claw-run 123                # Single issue: focus on GitHub issue #123
/claw-run --auto             # Autonomous: work until complete (no check-ins)
/claw-run --auto --max 30    # Autonomous with iteration limit
```

## Autonomous Mode (`--auto`)

**Hands-off execution** - Claude works through all items without waiting for user input.

### How It Works

1. Creates `.claw-autonomous` state file
2. Creates `.claw-session.md` with all selected items
3. Works through items one by one
4. Stop hook intercepts exit attempts
5. Loop continues until:
   - All items complete (all checkboxes checked)
   - Max iterations reached (default: 50)
   - Blocker encountered (creates `.claw-blocked`)
   - User runs `/claw-cancel`

### Starting Autonomous Mode

```
/claw-run --auto
```

Claude will:
1. Read `.claw/config.json`
2. List available items from sources
3. Let you select items (or use `--all` for everything)
4. Start working autonomously

### Safety Features

| Feature | Purpose |
|---------|---------|
| `--max <n>` | Limit iterations (default: 50) |
| `.claw-blocked` | Create this file to pause loop |
| `/claw-cancel` | Cancel loop immediately |
| Session file | Progress survives if anything fails |

### Completion Detection

The loop exits when `.claw-session.md` has no incomplete items:
- `- [x]` = complete
- `- [ ]` = incomplete

### Blocker Handling

If Claude encounters a blocker it can't resolve:

1. Creates `.claw-blocked` with description
2. Loop pauses on next iteration
3. User reviews and resolves
4. Delete `.claw-blocked` and run `/claw-run --auto` to resume

## Modes

### Batch Mode: `/run`

Select multiple items, work through sequentially.

1. Read `.claw/config.json` for configuration
2. List items from configured sources:
   - Obsidian: `bugs/`, `features/`, `improvements/`
   - GitHub: issues (if team mode)
3. Let user select items
4. Create `.claw-session.md`
5. Work through each item
6. Update progress as you go

### Single Issue Mode: `/run <number>`

Focus on one GitHub issue with iteration loop.

1. Fetch issue #<number> from GitHub
2. Create branch: `issue/<number>-<slug>`
3. Work with feedback loop (see below)

## Work Styles

Read `workMode` from config:

### Careful Mode (`workMode: "careful"`)

- **Show options** - Present 2-3 approaches before implementing
- **Small chunks** - Implement in tiny steps
- **Diff before commit** - Show changes, ask for approval
- **Frequent check-ins** - "Here's what I did, continue?"

### Fast Mode (`workMode: "fast"`)

- **Still scope properly** - Understand before implementing
- **Trust approach** - Pick best approach (no options shown)
- **Show result after** - Implement, then show what was done
- **Check in after completion** - Not during implementation

**Key insight:** Fast mode is NOT sloppy. It's "trust mode" - proper engineering, fewer interruptions.

## Single Issue Flow (Team Mode)

```
/run 123
  ↓
Fetch issue, create branch
  ↓
Understand requirement
  ↓
Write tests (if TDD enabled)
  ↓
Implement solution
  ↓
Run tests / verify
  ↓
Ask: "How does this look?"
```

**User can respond:**

| Response | Action |
|----------|--------|
| "Show diff" | Show git diff summary |
| "Need X changed" | Iterate on implementation |
| "Looks good, create PR" | Create PR (never merge) |
| "Done for now" | Commit, can resume later |
| "I need to review first" | Stop, user reviews code |

## Session File

Created at `.claw-session.md`:

```markdown
# Session: auth-improvements
Started: 2026-02-01 14:30
Mode: batch | single-issue
Branch: issue/123-fix-login

## Items

### 1. Fix login timeout
Source: bugs/fix-login-timeout.md
- [x] Understood
- [x] Tests written
- [x] Implementation
- [ ] Verified

### 2. Add remember me
Source: features/add-remember-me.md
- [ ] Understood
...

## Progress Log
- 14:30: Started session
- 14:35: Item 1 - tests written
- 14:50: Item 1 - implementation complete
```

## Session Recovery

**CRITICAL: After context compaction, read `.claw-session.md` to recover state.**

1. Check if `.claw-session.md` exists
2. Read current progress markers
3. Find first incomplete item
4. Continue from where left off
5. DO NOT restart completed items

## Team Mode Principles

- **PR is explicit** - Never auto-create, user must ask
- **Never merge** - Team reviews and merges
- **User controls pace** - Can pause, review, iterate
- **Verify first** - Run tests before asking for feedback

## Configuration Reference

From `.claw/config.json`:

```json
{
  "mode": "solo | team",
  "workMode": "careful | fast",
  "source": {
    "obsidian": true,
    "github": false
  },
  "apps": {
    "backend": {
      "path": ".",
      "devCommand": "make dev",
      "devUrl": "http://localhost:8080"
    },
    "web": {
      "path": "apps/web",
      "devCommand": "npm run dev",
      "devUrl": "http://localhost:3000"
    }
  },
  "testing": {
    "tdd": true,
    "runner": "jest"
  },
  "autoClose": "ask | never | always"
}
```

| Config | Effect |
|--------|--------|
| `source.obsidian` | List items from Obsidian folders |
| `source.github` | List items from GitHub issues |
| `workMode` | Careful or fast work style |
| `apps` | Per-app dev commands and URLs (for monorepos) |
| `testing.tdd` | Write tests before implementation |
| `autoClose` | How to handle closing issues |

## Working with Apps

When working on an item, check which app it affects and use the appropriate config:

1. Read the item to understand which app it targets
2. Look up the app in `config.apps`
3. Use `devCommand` to start the dev server
4. Use `devUrl` for E2E tests or manual verification
5. Run from `path` directory if not root

## Verification Screenshots

**After completing each item, offer to capture a verification screenshot:**

1. When tests pass and implementation is verified:
   - Ask: "Want to add a screenshot showing this working?"

2. If user pastes an image:
   - Read the pasted image path (shown when pasted)
   - Generate filename: `<type>-<slug>-done-<timestamp>.png`
   - Copy to Obsidian: `<vault>/<project>/attachments/`
   - Update the original note with a "## Verification" section

3. **Image handling:**
   ```bash
   cp "/var/folders/.../paste-XXX.png" "~/Documents/Obsidian/Projects/<project>/attachments/<filename>.png"
   ```

4. **Update the Obsidian note:**
   - Add `## Verification` section if not present
   - Add `![[attachments/<filename>.png]]`
   - Update status to "completed"

This creates visual documentation that the fix/feature works, valuable for:
- Future debugging (what did it look like when working?)
- PR reviews (screenshots in description)
- Knowledge base (documented solutions)
