# Wind-Down System Integration Plan

**Issue**: #26 - Integrate wind-down system into claw
**Status**: 🚧 In Progress
**Target**: Make wind-down part of claw's portable setup

---

## Current State Analysis

### Existing Components

**Scripts** (5 files in `~/bin/`):
1. `wind-down.sh` - Main interactive brain dump script (8.3KB)
2. `wind-down-auto.sh` - Auto-trigger with notifications
3. `wind-down-iterm.sh` - iTerm launcher
4. `wind-down-notify.sh` - Notification sender
5. `wind-down-check.sh` - Terminal warning system

**Launchd Agents** (2 files in `~/Library/LaunchAgents/`):
1. `com.winddown.auto-830pm.plist` - Gym day auto-trigger
2. `com.winddown.auto-10pm.plist` - No-gym day auto-trigger

**Claude Integration**:
1. `~/.claude/rules/time-awareness.md` - Morning gym check, cutoff warnings
2. `~/.claude/skills/wind-down/` - `/wind-down` command

**Shell Integration**:
- `~/.zshrc` sources `wind-down-check.sh` for terminal warnings

**Dependencies**:
- Obsidian vault at `~/Documents/Obsidian/Daily/`
- Git repos at `~/work/` (work) and `~/som/` (personal)
- iTerm2 or Terminal.app

---

## Integration Architecture

### Target Structure

```
claude-code-setup/
├── bin/
│   └── claw               # Main binary (already exists)
├── lib/
│   ├── wind-down/         # NEW: Wind-down scripts
│   │   ├── wind-down.sh
│   │   ├── wind-down-auto.sh
│   │   ├── wind-down-iterm.sh
│   │   ├── wind-down-notify.sh
│   │   └── wind-down-check.sh
│   └── ... (other libs)
├── templates/
│   ├── .claude/
│   │   ├── rules/
│   │   │   └── time-awareness.md  # ALREADY EXISTS
│   │   └── skills/
│   │       └── wind-down/          # NEW: Wind-down skill
│   │           ├── SKILL.md
│   │           └── wind-down.md
│   └── launchd/                    # NEW: Launch agent templates
│       ├── com.winddown.auto-830pm.plist.template
│       └── com.winddown.auto-10pm.plist.template
└── docs/
    └── wind-down-setup.md          # NEW: User setup guide
```

### Installation Flow

```bash
# User runs
./install.sh

# Which includes
setup_wind_down() {
    # 1. Copy scripts to ~/bin/
    # 2. Make executable
    # 3. Copy launchd agents (with config substitution)
    # 4. Load launchd agents
    # 5. Add to ~/.zshrc for terminal warnings
    # 6. Copy Claude rules/skills (already done by install.sh)
}
```

---

## Configuration System

### Config File: `~/.claw/wind-down.conf`

```bash
# Wind-Down Configuration
OBSIDIAN_VAULT_PATH="$HOME/Documents/Obsidian/Daily"
GIT_WORK_DIR="$HOME/work"
GIT_PERSONAL_DIR="$HOME/som"
GYM_DEFAULT_TIME="21:00"  # 9pm
GYM_DAY_CUTOFF="20:30"     # 8:30pm
NO_GYM_CUTOFF="22:00"      # 10pm
TERMINAL_APP="auto"        # auto, iterm, terminal
ENABLE_AUTO_OPEN="true"
ENABLE_TERMINAL_WARNINGS="true"
```

### Template Variable Substitution

Launchd agents and scripts will use `{{VARIABLE}}` syntax:

```xml
<!-- Before -->
<string>/Users/baicoianuionut/bin/wind-down-auto.sh</string>

<!-- After substitution -->
<string>{{HOME}}/bin/wind-down-auto.sh</string>
```

---

## Implementation Phases

### Phase 1: File Migration ✅ (This PR)

- [x] Copy wind-down scripts to `lib/wind-down/`
- [x] Copy wind-down skill to `templates/.claude/skills/wind-down/`
- [x] Copy launchd agents to `templates/launchd/` (as templates)
- [x] Create configuration structure
- [x] Document integration plan

### Phase 2: Installation Integration (Next)

- [ ] Add `setup_wind_down()` function to `install.sh`
- [ ] Create config file generation logic
- [ ] Add variable substitution for templates
- [ ] Update README with wind-down setup instructions
- [ ] Test installation on clean system

### Phase 3: Configuration Management (Future)

- [ ] Add `claw wind-down config` command
- [ ] Interactive setup wizard
- [ ] Validation of Obsidian path, git directories
- [ ] Enable/disable individual components
- [ ] Update launchd agents on config change

### Phase 4: Advanced Features (Future)

- [ ] Support for Linux (systemd timers instead of launchd)
- [ ] Multiple git directory support
- [ ] Custom cutoff time per day of week
- [ ] Integration with calendar APIs
- [ ] Metrics dashboard (completion rate, energy trends)

---

## Design Decisions

### 1. Obsidian: Optional Dependency

**Decision**: Make Obsidian optional, fallback to plain markdown in `~/.claw/daily/`

**Rationale**:
- Not all users have Obsidian
- Core functionality (brain dump, tracking) works without it
- Can still integrate with Obsidian if available

**Implementation**:
```bash
if [[ -d "$OBSIDIAN_VAULT_PATH" ]]; then
    DAILY_LOG_PATH="$OBSIDIAN_VAULT_PATH/$(date +%Y-%m-%d).md"
else
    DAILY_LOG_PATH="$HOME/.claw/daily/$(date +%Y-%m-%d).md"
fi
```

### 2. Git Directories: Configurable

**Decision**: Store in config, default to `~/work` and `~/som`, support multiple

**Configuration**:
```bash
GIT_DIRECTORIES=(
    "$HOME/work"
    "$HOME/som"
    "$HOME/projects"
)
```

### 3. Terminal App: Auto-Detect

**Decision**: Auto-detect iTerm2 vs Terminal, allow override

**Logic**:
```bash
if [[ "$TERMINAL_APP" == "auto" ]]; then
    if [[ -d "/Applications/iTerm.app" ]]; then
        TERMINAL_APP="iterm"
    else
        TERMINAL_APP="terminal"
    fi
fi
```

### 4. Cutoff Times: Configurable Per User

**Default Values**:
- Gym day: 8:30pm (allows 30min for wind-down before 9pm gym)
- No gym: 10pm (standard sleep preparation)

**Override**: Via config file or command line

---

## Migration Path for Existing Users

### Scenario: User Already Has Wind-Down System

**Detection**:
```bash
if [[ -f "$HOME/bin/wind-down.sh" ]]; then
    echo "ℹ️  Existing wind-down system detected"
    echo "Would you like to:"
    echo "  1) Migrate to claw-managed system (recommended)"
    echo "  2) Keep existing system"
    echo "  3) Install side-by-side (not recommended)"
fi
```

**Migration Process**:
1. Backup existing files to `~/.claw/wind-down-backup/`
2. Extract configuration from existing scripts
3. Generate `~/.claw/wind-down.conf` with extracted values
4. Unload old launchd agents
5. Install new claw-managed system
6. Verify configuration matches old system
7. Test with dry-run mode

---

## Testing Strategy

### Unit Tests

```bash
# tests/wind_down.bats
@test "wind-down: config file generation"
@test "wind-down: Obsidian path validation"
@test "wind-down: git directory scanning"
@test "wind-down: cutoff time calculation"
@test "wind-down: launchd agent creation"
```

### Integration Tests

```bash
@test "wind-down: full installation on clean system"
@test "wind-down: migration from existing system"
@test "wind-down: config updates propagate correctly"
@test "wind-down: launchd agents trigger at correct times"
```

### Manual Test Checklist

- [ ] Install on clean macOS system
- [ ] Verify scripts are executable
- [ ] Verify launchd agents load successfully
- [ ] Trigger wind-down manually
- [ ] Wait for automatic trigger at cutoff
- [ ] Verify daily note creation (Obsidian or fallback)
- [ ] Check terminal warning appears
- [ ] Test config changes propagate
- [ ] Uninstall and verify cleanup

---

## Documentation Requirements

### User-Facing Docs

1. **Setup Guide** (`docs/wind-down-setup.md`)
   - Quick start (5-minute setup)
   - Configuration options
   - Troubleshooting
   - FAQ

2. **README Update**
   - Add wind-down system to features list
   - Link to setup guide
   - Show example workflow

3. **Command Reference**
   - `claw wind-down` - Run wind-down manually
   - `claw wind-down config` - Configure system
   - `claw wind-down status` - Show current status
   - `claw wind-down test` - Dry-run test

### Developer Docs

1. **Integration Guide** (this document)
2. **Architecture Decisions** (inline in code)
3. **Testing Guide** (test setup and scenarios)

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaks existing user setup | HIGH | Detect existing setup, offer migration, backup first |
| Launchd agent permissions | MEDIUM | Clear docs, fallback to manual trigger |
| Obsidian path changes | MEDIUM | Config file, validation on startup |
| Cross-platform issues | MEDIUM | Phase 4 addresses Linux, document macOS-only for now |
| Time zone issues | LOW | Use system local time, not UTC |

---

## Success Criteria

### Minimum Viable Integration (Phase 1-2)

- ✅ All wind-down files in claw codebase
- ✅ Installation includes wind-down setup
- ✅ Config file system works
- ✅ Works on clean macOS system
- ✅ Documentation exists
- ✅ Basic tests pass

### Full Integration (Phase 3-4)

- Interactive configuration wizard
- Migration from existing setups
- Config management commands
- Comprehensive test coverage
- Linux support (systemd)

---

## Timeline Estimate

| Phase | Effort | Dependencies |
|-------|--------|--------------|
| Phase 1 | 2 hours | None - just file migration |
| Phase 2 | 4 hours | Phase 1 complete |
| Phase 3 | 6 hours | Phase 2 complete, user feedback |
| Phase 4 | 8+ hours | Phase 3 complete, Linux testing env |

**Total for MVP (Phase 1-2)**: ~6 hours
**Total for Full Integration**: ~20 hours

---

## Next Steps (Immediate)

1. ✅ Create this integration plan document
2. ⏳ Copy scripts to `lib/wind-down/`
3. ⏳ Copy skill to `templates/.claude/skills/wind-down/`
4. ⏳ Create launchd templates with variable substitution
5. ⏳ Create default config structure
6. ⏳ Document in README

**Then**: Commit Phase 1, create follow-up issue for Phase 2

---

**Last Updated**: 2026-01-10
**Status**: Phase 1 in progress
**Next Review**: After Phase 1 completion
