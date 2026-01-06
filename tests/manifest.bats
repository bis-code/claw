#!/usr/bin/env bats
# Tests for manifest management and smart upgrades

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Manifest Functions
# ============================================================================

@test "get_installed_version: returns 0.0.0 for no manifest" {
    mkdir -p "$TMP_DIR/project"
    run get_installed_version "$TMP_DIR/project"
    assert_success
    assert_output "0.0.0"
}

@test "get_installed_version: returns version from manifest" {
    mkdir -p "$TMP_DIR/project/.claude"
    cat > "$TMP_DIR/project/.claude/manifest.json" << 'EOF'
{
  "version": "1.2.3",
  "preset": "base"
}
EOF
    run get_installed_version "$TMP_DIR/project"
    assert_success
    assert_output "1.2.3"
}

@test "get_installed_preset: returns full for no manifest" {
    mkdir -p "$TMP_DIR/project"
    run get_installed_preset "$TMP_DIR/project"
    assert_success
    assert_output "full"
}

@test "get_installed_preset: returns preset from manifest" {
    mkdir -p "$TMP_DIR/project/.claude"
    cat > "$TMP_DIR/project/.claude/manifest.json" << 'EOF'
{
  "version": "1.0.0",
  "preset": "unity"
}
EOF
    run get_installed_preset "$TMP_DIR/project"
    assert_success
    assert_output "unity"
}

@test "calc_checksum: returns empty for nonexistent file" {
    run calc_checksum "$TMP_DIR/nonexistent"
    assert_success
    assert_output ""
}

@test "calc_checksum: returns valid checksum" {
    echo "test content" > "$TMP_DIR/testfile"
    run calc_checksum "$TMP_DIR/testfile"
    assert_success
    assert [ ${#output} -eq 64 ]  # SHA256 is 64 hex chars
}

@test "is_file_modified: returns false for nonexistent file" {
    mkdir -p "$TMP_DIR/project"
    run is_file_modified "$TMP_DIR/project" "nonexistent.md"
    assert_failure  # File doesn't exist = not modified
}

@test "is_file_modified: returns true for file not in manifest" {
    mkdir -p "$TMP_DIR/project"
    echo "content" > "$TMP_DIR/project/file.md"
    run is_file_modified "$TMP_DIR/project" "file.md"
    assert_success  # File exists but not in manifest = treated as modified
}

@test "write_manifest: creates valid JSON" {
    mkdir -p "$TMP_DIR/project"
    write_manifest "$TMP_DIR/project" "1.0.0" "base" "file1.md:abc123" "file2.md:def456"

    run cat "$TMP_DIR/project/.claude/manifest.json"
    assert_success
    assert_output --partial '"version": "1.0.0"'
    assert_output --partial '"preset": "base"'
    assert_output --partial '"generator": "claw"'
    assert_output --partial '"path": "file1.md"'
}

# ============================================================================
# Smart Upgrade Behavior
# ============================================================================

@test "smart upgrade: detects user-modified files" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    # First init
    "$PROJECT_ROOT/bin/claw" init --preset base

    # Modify a managed file
    echo "# User modification" >> .claude/rules/security.md

    # Upgrade should skip modified file
    run "$PROJECT_ROOT/bin/claw" upgrade
    assert_success
    assert_output --partial "Skipped"
    assert_output --partial "locally modified"
}

@test "smart upgrade: force overwrites modified files" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    # First init
    "$PROJECT_ROOT/bin/claw" init --preset base

    # Modify a managed file
    echo "# User modification" >> .claude/rules/security.md

    # Force upgrade should overwrite
    run "$PROJECT_ROOT/bin/claw" upgrade --force
    assert_success
    assert_output --partial "Forced"
}

@test "smart upgrade: preserves unmanaged custom files" {
    mkdir -p "$TMP_DIR/project/.claude/commands"
    cd "$TMP_DIR/project"

    # Create custom file before init
    echo "# Custom command" > .claude/commands/my-custom.md

    # Init
    "$PROJECT_ROOT/bin/claw" init --preset base

    # Custom file should exist
    assert [ -f ".claude/commands/my-custom.md" ]

    # Upgrade
    "$PROJECT_ROOT/bin/claw" upgrade

    # Custom file should still exist
    assert [ -f ".claude/commands/my-custom.md" ]
}

@test "smart upgrade: up-to-date files show no changes" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    # First init
    "$PROJECT_ROOT/bin/claw" init --preset base

    # Upgrade with no changes should show "Already Up to Date"
    run "$PROJECT_ROOT/bin/claw" upgrade
    assert_success
    assert_output --partial "Already Up to Date"
}

# ============================================================================
# Check Command (Dry Run)
# ============================================================================

@test "check: shows [OK] for up-to-date files" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    # First init
    "$PROJECT_ROOT/bin/claw" init --preset base

    # Check should show OK
    run "$PROJECT_ROOT/bin/claw" check --preset base
    assert_success
    assert_output --partial "[OK]"
}

@test "check: shows [MODIFIED] for user-modified files" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    # First init
    "$PROJECT_ROOT/bin/claw" init --preset base

    # Modify a managed file
    echo "# User modification" >> .claude/rules/security.md

    # Check should show modified
    run "$PROJECT_ROOT/bin/claw" check --preset base
    assert_success
    assert_output --partial "[MODIFIED]"
}

@test "check: does not modify files" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    # First init
    "$PROJECT_ROOT/bin/claw" init --preset base

    # Get original checksum
    local original=$(shasum -a 256 .claude/manifest.json | cut -d' ' -f1)

    # Modify a file to trigger potential updates
    echo "# User modification" >> .claude/rules/security.md

    # Check should NOT modify manifest
    "$PROJECT_ROOT/bin/claw" check --preset base

    local after=$(shasum -a 256 .claude/manifest.json | cut -d' ' -f1)
    assert [ "$original" == "$after" ]
}

# ============================================================================
# CLI Integration
# ============================================================================

@test "claw check: works without arguments" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    "$PROJECT_ROOT/bin/claw" init --preset base

    run "$PROJECT_ROOT/bin/claw" check
    assert_success
    assert_output --partial "Checking for updates"
}

@test "claw upgrade: preserves preset from manifest" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    # Init with unity preset
    "$PROJECT_ROOT/bin/claw" init --preset unity

    # Verify manifest has unity preset
    run cat .claude/manifest.json
    assert_output --partial '"preset": "unity"'

    # Upgrade without specifying preset
    run "$PROJECT_ROOT/bin/claw" upgrade
    assert_success

    # Should still be unity preset
    run cat .claude/manifest.json
    assert_output --partial '"preset": "unity"'
}

@test "claw init: version tracking shows installed vs available" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    # First init
    "$PROJECT_ROOT/bin/claw" init --preset base

    # Second init should show version comparison
    run "$PROJECT_ROOT/bin/claw" init --preset base
    assert_success
    assert_output --partial "Installed:"
    assert_output --partial "Available:"
}
