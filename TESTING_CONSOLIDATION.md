# Testing Command Consolidation

Guide for testing the `/auto` command consolidation locally.

## Quick Automated Testing

### Run BATS Tests

```bash
cd /Users/baicoianuionut/som/personal-projects/claude-code-setup

# Run consolidation tests
bats tests/command_consolidation.bats

# Or run all tests
make test-full
```

**Expected result:** All 30 tests should pass ✅

### What the Tests Verify

- ✅ New `/auto` command files exist
- ✅ Deprecation notices for `/auto-pilot` are in place
- ✅ `/plan-day` documented as alias for `/auto --plan-only`
- ✅ `/autonomous` and `/brainstorm` marked as internal
- ✅ All documentation updated (CLAUDE.md, README.md)
- ✅ All rule files reference `/auto` not `/auto-pilot`
- ✅ Migration guides present in deprecation files

---

## Manual Testing in Claude Code

### 1. Create a Test Project

```bash
# Create clean test directory
mkdir -p ~/test-auto-consolidation
cd ~/test-auto-consolidation
git init

# Create dummy files
echo "console.log('test')" > index.js
echo "# Test Project" > README.md
git add . && git commit -m "Initial commit"

# Create a mock GitHub issue for testing
echo "Test issue for planning" > issue.txt
```

### 2. Install Templates

```bash
# Copy templates to test project
cp -r /Users/baicoianuionut/som/personal-projects/claude-code-setup/templates/.claude .
cp /Users/baicoianuionut/som/personal-projects/claude-code-setup/templates/CLAUDE.md .
```

### 3. Start Claude Code

```bash
cd ~/test-auto-consolidation
claude  # or claw
```

### 4. Test Each Command

Inside Claude Code session:

#### Test 1: New `/auto` command

```bash
# Should show new unified documentation
/auto

# Expected output:
# - "One command to rule them all"
# - Documentation for --plan-only, --skip-discovery
# - Invocation examples
```

#### Test 2: Deprecated `/auto-pilot`

```bash
/auto-pilot

# Expected output:
# - ⚠️ DEPRECATED warning
# - Redirect notice to /auto
# - Migration guide
```

#### Test 3: `/plan-day` alias

```bash
/plan-day --hours 4

# Expected output:
# - Note about being an alias for /auto --plan-only
# - Recommendation to use /auto
# - Still functions as expected
```

#### Test 4: Internal commands

```bash
/autonomous

# Expected output:
# - Note: "This is an internal command called by /auto"
# - Recommendation to use /auto instead

/brainstorm

# Expected output:
# - Note: "This is an internal command called by /auto"
# - Recommendation to use /auto or /auto --plan-only
```

### 5. Test Flags

```bash
# Test --plan-only flag
/auto --plan-only --hours 4

# Should: Discovery + Planning, NO execution

# Test --skip-discovery flag
/auto --skip-discovery --hours 4

# Should: Skip discovery, plan and execute existing issues

# Test --hours flag
/auto --hours 8

# Should: Run full cycle with 8-hour budget

# Test --focus flag
/auto --focus "billing" --hours 4

# Should: Focus only on billing-related work
```

### 6. Verify Documentation

```bash
# Read CLAUDE.md
cat CLAUDE.md

# Should contain:
# - "## Autonomous Development: /auto Command" section
# - Quick start examples with /auto
# - Mention of /plan-day as alias

# Check command files
ls .claude/commands/

# Should see:
# - auto.md (new unified command)
# - auto-pilot.md (deprecation notice)
# - plan-day.md (updated with alias info)
# - autonomous.md (marked as internal)
# - brainstorm.md (marked as internal)
```

---

## Testing Migration Path

### Simulate Existing User Upgrade

```bash
# 1. Create "old" setup (pre-consolidation)
mkdir -p ~/test-migration
cd ~/test-migration
git init

# Manually create old-style files
mkdir -p .claude/skills/daily-workflow
mkdir -p .claude/commands

# Create old auto-pilot.md with old content
echo "# /auto-pilot" > .claude/skills/daily-workflow/auto-pilot.md
echo "Old content here" >> .claude/skills/daily-workflow/auto-pilot.md

# 2. "Upgrade" by copying new templates
cp -r /Users/baicoianuionut/som/personal-projects/claude-code-setup/templates/.claude .
cp /Users/baicoianuionut/som/personal-projects/claude-code-setup/templates/CLAUDE.md .

# 3. Verify both old and new files exist
ls .claude/skills/daily-workflow/

# Should see:
# - auto.md (new)
# - auto-pilot.md (deprecation notice)
# - plan-day.md (updated)

# 4. Test in Claude Code
claude

# Inside session:
/auto            # Should work with new command
/auto-pilot      # Should show deprecation warning
/plan-day        # Should work as alias
```

---

## Testing in Real Project

### Option 1: Test in Non-Critical Branch

```bash
# In your actual project
cd ~/projects/your-project
git checkout -b test-auto-consolidation

# Copy new templates
cp -r /path/to/claude-code-setup/templates/.claude .
cp /path/to/claude-code-setup/templates/CLAUDE.md .

# Test commands
claude

# Inside Claude:
/auto --plan-only --hours 4

# If satisfied:
git add .
git commit -m "feat: consolidate commands to /auto"
git checkout main
git merge test-auto-consolidation
```

### Option 2: Use Dev Mode

```bash
# In claude-code-setup repo
cd /Users/baicoianuionut/som/personal-projects/claude-code-setup
make dev

# Now claw will use your working directory instantly
cd ~/projects/any-project
claw

# Test commands immediately - changes reflect instantly
```

---

## Regression Testing

Run full test suite to ensure nothing broke:

```bash
cd /Users/baicoianuionut/som/personal-projects/claude-code-setup

# Run all tests
bats tests/*.bats

# Or use make
make test-full
```

**Should pass:**
- ✅ integration.bats
- ✅ output.bats
- ✅ real_world.bats
- ✅ utils.bats
- ✅ boolean_params.bats
- ✅ command_consolidation.bats (new)

---

## Known Issues & Troubleshooting

### Issue: Old `/auto-pilot` command doesn't work

**Cause:** Deprecation file not present

**Fix:**
```bash
# Ensure deprecation files exist
ls .claude/skills/daily-workflow/auto-pilot.md
ls .claude/commands/auto-pilot.md

# If missing, copy from templates
cp /path/to/templates/.claude/skills/daily-workflow/auto-pilot.md .claude/skills/daily-workflow/
cp /path/to/templates/.claude/commands/auto-pilot.md .claude/commands/
```

### Issue: `/plan-day` doesn't show alias notice

**Cause:** Old plan-day.md not updated

**Fix:**
```bash
# Replace with new version
cp /path/to/templates/.claude/skills/daily-workflow/plan-day.md .claude/skills/daily-workflow/
cp /path/to/templates/.claude/commands/plan-day.md .claude/commands/
```

### Issue: Tests failing

**Cause:** Template files out of sync

**Fix:**
```bash
# Regenerate from source
cd /Users/baicoianuionut/som/personal-projects/claude-code-setup

# Ensure all files are committed
git status

# Re-run tests
bats tests/command_consolidation.bats -t
```

---

## Cleanup After Testing

```bash
# Remove test directories
rm -rf ~/test-auto-consolidation
rm -rf ~/test-migration

# If using dev mode, restore normal install
cd /Users/baicoianuionut/som/personal-projects/claude-code-setup
make install
```

---

## Success Criteria

The consolidation is working correctly if:

✅ All 30 BATS tests pass
✅ `/auto` command shows unified documentation
✅ `/auto --plan-only` works (discovery + planning, no execution)
✅ `/auto --skip-discovery` works (planning + execution, no discovery)
✅ `/auto-pilot` shows deprecation warning
✅ `/plan-day` shows alias notice and recommends `/auto`
✅ `/autonomous` and `/brainstorm` marked as internal
✅ CLAUDE.md documents new `/auto` command
✅ README.md updated with consolidated command table
✅ No references to `/auto-pilot` except in deprecation files

---

## Next Steps After Testing

1. **If all tests pass:** Proceed to commit and push
2. **If tests fail:** Review failures, fix issues, re-test
3. **After merging:** Update setup script with consolidation
4. **For users:** Document migration path in release notes
