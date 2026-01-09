#!/usr/bin/env bats
# Unit tests for files.sh file management functions

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup function runs before each test
setup() {
    # Get the project root directory
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export PROJECT_ROOT

    # Create a temporary directory for tests
    TEST_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TEST_DIR

    # Source required libraries
    source "$PROJECT_ROOT/lib/output.sh"
    source "$PROJECT_ROOT/lib/manifest.sh"
    source "$PROJECT_ROOT/lib/files.sh"

    # Reset tracking arrays before each test
    reset_tracking
}

# Teardown function runs after each test
teardown() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" && "$TEST_DIR" == /tmp/* ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# ============================================================================
# Tracking Array Tests
# ============================================================================

@test "files.sh: tracking arrays are initialized" {
    # Arrays should be empty after reset in setup
    [[ ${#MANAGED_FILES[@]} -eq 0 ]]
    [[ ${#CREATED_FILES[@]} -eq 0 ]]
    [[ ${#UPDATED_FILES[@]} -eq 0 ]]
    [[ ${#SKIPPED_FILES[@]} -eq 0 ]]
    [[ ${#CONFLICT_FILES[@]} -eq 0 ]]
}

@test "reset_tracking: clears all tracking arrays" {
    # Add some dummy data
    MANAGED_FILES=("file1")
    CREATED_FILES=("file2")
    UPDATED_FILES=("file3")
    SKIPPED_FILES=("file4")
    CONFLICT_FILES=("file5")

    # Reset (not in subshell)
    reset_tracking

    # Verify arrays are empty
    [[ ${#MANAGED_FILES[@]} -eq 0 ]]
    [[ ${#CREATED_FILES[@]} -eq 0 ]]
    [[ ${#UPDATED_FILES[@]} -eq 0 ]]
    [[ ${#SKIPPED_FILES[@]} -eq 0 ]]
    [[ ${#CONFLICT_FILES[@]} -eq 0 ]]
}

# ============================================================================
# create_managed_file: New File Tests
# ============================================================================

@test "create_managed_file: creates new file" {
    run create_managed_file "$TEST_DIR" "test.txt" "Hello World" "test file" false false
    assert_success
    assert_output --partial "Created:"
    assert_output --partial "test.txt"

    # Verify file exists
    [[ -f "$TEST_DIR/test.txt" ]]

    # Verify content
    [[ "$(cat "$TEST_DIR/test.txt")" == "Hello World" ]]
}

@test "create_managed_file: creates file with description" {

    run create_managed_file "$TEST_DIR" "test.txt" "Content" "My Description" false false
    assert_success
    assert_output --partial "My Description"
}

@test "create_managed_file: creates nested directory structure" {

    run create_managed_file "$TEST_DIR" "nested/path/file.txt" "Content" "" false false
    assert_success

    # Verify nested directories were created
    [[ -d "$TEST_DIR/nested/path" ]]
    [[ -f "$TEST_DIR/nested/path/file.txt" ]]
}

@test "create_managed_file: dry-run shows [NEW] for new files" {
    run create_managed_file "$TEST_DIR" "test.txt" "Content" "" false true
    assert_success
    assert_output --partial "[NEW]"
    assert_output --partial "test.txt"

    # File should NOT be created
    [[ ! -f "$TEST_DIR/test.txt" ]]
}

# ============================================================================
# create_managed_file: Update Tests
# ============================================================================

@test "create_managed_file: updates existing file with force flag" {
    # Create initial file
    mkdir -p "$TEST_DIR"
    printf "Old Content\n" > "$TEST_DIR/test.txt"

    # Force update
    run create_managed_file "$TEST_DIR" "test.txt" "New Content" "" true false
    assert_success
    assert_output --partial "Forced:"

    # Verify content changed
    [[ "$(cat "$TEST_DIR/test.txt")" == "New Content" ]]
}

@test "create_managed_file: skips update when content identical" {

    # Create initial file
    mkdir -p "$TEST_DIR"
    printf "Same Content\n" > "$TEST_DIR/test.txt"

    # Create manifest
    mkdir -p "$TEST_DIR/.claude"
    local checksum=$(calc_checksum "$TEST_DIR/test.txt")
    cat > "$TEST_DIR/.claude/manifest.json" <<EOF
{
  "version": "1.0.0",
  "preset": "full",
  "files": [
    {
      "path": "test.txt",
      "checksum": "$checksum"
    }
  ]
}
EOF

    # Try to update with same content
    run create_managed_file "$TEST_DIR" "test.txt" "Same Content" "" false false
    assert_success
    # Should not output anything for unchanged files in normal mode
    refute_output --partial "Updated:"
    refute_output --partial "Created:"

    # Verify no updates tracked
    [[ ${#UPDATED_FILES[@]} -eq 0 ]]
}

@test "create_managed_file: dry-run with force shows intent to overwrite" {
    # Create initial file
    mkdir -p "$TEST_DIR"
    printf "Old Content\n" > "$TEST_DIR/test.txt"

    # Dry run force
    run create_managed_file "$TEST_DIR" "test.txt" "New Content" "" true true
    assert_success
    assert_output --partial "[FORCE]"

    # File should NOT be changed in dry-run
    [[ "$(head -n 1 "$TEST_DIR/test.txt")" == "Old Content" ]]
}

@test "create_managed_file: handles content with special characters" {
    local special_content="Line with \$vars and 'quotes' and \"double quotes\""

    run create_managed_file "$TEST_DIR" "test.txt" "$special_content" "" false false
    assert_success

    # Verify file was created with correct content
    [[ -f "$TEST_DIR/test.txt" ]]
    [[ "$(cat "$TEST_DIR/test.txt")" == "$special_content" ]]
}

# ============================================================================
# create_managed_file: Force Flag Tests
# ============================================================================

@test "create_managed_file: force flag overwrites modified files" {

    # Create initial managed file
    mkdir -p "$TEST_DIR"
    echo "Original Content" > "$TEST_DIR/test.txt"

    # Create manifest showing original state
    mkdir -p "$TEST_DIR/.claude"
    local original_checksum=$(printf "Original Content\n" | shasum -a 256 | cut -d' ' -f1)
    cat > "$TEST_DIR/.claude/manifest.json" <<EOF
{
  "version": "1.0.0",
  "preset": "full",
  "files": [
    {
      "path": "test.txt",
      "checksum": "$original_checksum"
    }
  ]
}
EOF

    # User modifies the file
    echo "User Modified" > "$TEST_DIR/test.txt"

    # Force overwrite
    run create_managed_file "$TEST_DIR" "test.txt" "Forced Content" "" true false
    assert_success
    assert_output --partial "Forced:"

    # Verify content was overwritten
    [[ "$(cat "$TEST_DIR/test.txt")" == "Forced Content" ]]
}

@test "create_managed_file: dry-run force shows [FORCE]" {

    # Create initial file
    mkdir -p "$TEST_DIR"
    echo "Content" > "$TEST_DIR/test.txt"

    # Dry run force
    run create_managed_file "$TEST_DIR" "test.txt" "New Content" "" true true
    assert_success
    assert_output --partial "[FORCE]"

    # File should NOT be changed
    [[ "$(cat "$TEST_DIR/test.txt")" == "Content" ]]
}

# ============================================================================
# create_managed_file: Conflict Detection Tests
# ============================================================================

@test "create_managed_file: detects user-modified files" {

    # Create initial managed file
    mkdir -p "$TEST_DIR"
    echo "Original Content" > "$TEST_DIR/test.txt"

    # Create manifest showing original state
    mkdir -p "$TEST_DIR/.claude"
    local original_checksum=$(printf "Original Content\n" | shasum -a 256 | cut -d' ' -f1)
    cat > "$TEST_DIR/.claude/manifest.json" <<EOF
{
  "version": "1.0.0",
  "preset": "full",
  "files": [
    {
      "path": "test.txt",
      "checksum": "$original_checksum"
    }
  ]
}
EOF

    # User modifies the file
    echo "User Modified" > "$TEST_DIR/test.txt"

    # Try to update (without force)
    run create_managed_file "$TEST_DIR" "test.txt" "New Content" "" false false
    assert_success
    assert_output --partial "Skipped:"
    assert_output --partial "locally modified"

    # Verify file was NOT overwritten
    [[ "$(cat "$TEST_DIR/test.txt")" == "User Modified" ]]
}

@test "create_managed_file: dry-run shows [MODIFIED] for conflicts" {

    # Create initial managed file
    mkdir -p "$TEST_DIR"
    echo "Original Content" > "$TEST_DIR/test.txt"

    # Create manifest
    mkdir -p "$TEST_DIR/.claude"
    local original_checksum=$(printf "Original Content\n" | shasum -a 256 | cut -d' ' -f1)
    cat > "$TEST_DIR/.claude/manifest.json" <<EOF
{
  "version": "1.0.0",
  "preset": "full",
  "files": [
    {
      "path": "test.txt",
      "checksum": "$original_checksum"
    }
  ]
}
EOF

    # User modifies
    echo "User Modified" > "$TEST_DIR/test.txt"

    # Dry run
    run create_managed_file "$TEST_DIR" "test.txt" "New Content" "" false true
    assert_success
    assert_output --partial "[MODIFIED]"
    assert_output --partial "use --force to overwrite"
}

# ============================================================================
# create_managed_file: Checksum Tests
# ============================================================================

@test "create_managed_file: calculates correct checksum with trailing newline" {
    run create_managed_file "$TEST_DIR" "test.txt" "Content" "" false false
    assert_success

    # Verify file was created
    [[ -f "$TEST_DIR/test.txt" ]]
}

@test "create_managed_file: handles multi-line content" {

    local content="Line 1
Line 2
Line 3"

    run create_managed_file "$TEST_DIR" "test.txt" "$content" "" false false
    assert_success

    # Verify file exists and content matches
    [[ -f "$TEST_DIR/test.txt" ]]
    [[ "$(cat "$TEST_DIR/test.txt")" == "$content" ]]
}

@test "create_managed_file: handles empty content" {

    run create_managed_file "$TEST_DIR" "test.txt" "" "" false false
    assert_success

    # Verify file exists
    [[ -f "$TEST_DIR/test.txt" ]]
    # File should be empty (just newline)
    [[ "$(wc -c < "$TEST_DIR/test.txt")" -eq 1 ]]
}

# ============================================================================
# print_summary Tests
# ============================================================================

@test "print_summary: shows 'Already Up to Date' when no changes" {

    run print_summary "1.0.0" false false
    assert_success
    assert_output --partial "Already Up to Date"
    assert_output --partial "v1.0.0"
}

@test "print_summary: shows 'Setup Complete' when files created" {
    CREATED_FILES=("file1.txt" "file2.txt")

    run print_summary "1.0.0" false false
    assert_success
    assert_output --partial "Setup Complete!"
    assert_output --partial "Created:"
    assert_output --partial "2 files"
}

@test "print_summary: shows 'Setup Complete' when files updated" {
    UPDATED_FILES=("file1.txt")

    run print_summary "1.0.0" false false
    assert_success
    assert_output --partial "Setup Complete!"
    assert_output --partial "Updated:"
    assert_output --partial "1 files"
}

@test "print_summary: shows skipped files count" {
    SKIPPED_FILES=("file1.txt" "file2.txt" "file3.txt")

    run print_summary "1.0.0" false false
    assert_success
    assert_output --partial "Skipped:"
    assert_output --partial "3 files"
    assert_output --partial "locally modified"
}

@test "print_summary: shows conflict files count" {
    CONFLICT_FILES=("file1.txt" "file2.txt")

    run print_summary "1.0.0" false false
    assert_success
    assert_output --partial "Conflicts:"
    assert_output --partial "2 files"
    assert_output --partial "use --force to overwrite"
}

@test "print_summary: check-only mode shows 'Check Complete'" {

    run print_summary "1.0.0" true false
    assert_success
    assert_output --partial "Check Complete"
}

@test "print_summary: shows next steps in normal mode" {
    CREATED_FILES=("file1.txt")

    run print_summary "1.0.0" false false
    assert_success
    assert_output --partial "Next steps:"
    assert_output --partial "Edit CLAUDE.md"
    assert_output --partial "claw check"
}

@test "print_summary: does not show next steps in dry-run mode" {
    CREATED_FILES=("file1.txt")

    run print_summary "1.0.0" false true
    assert_success
    refute_output --partial "Next steps:"
}

@test "print_summary: shows force hint when files skipped" {
    SKIPPED_FILES=("file1.txt")

    run print_summary "1.0.0" false false
    assert_success
    assert_output --partial "Some files were skipped"
    assert_output --partial "--force"
}

@test "print_summary: displays all counts together" {
    CREATED_FILES=("file1.txt")
    UPDATED_FILES=("file2.txt" "file3.txt")
    SKIPPED_FILES=("file4.txt")
    CONFLICT_FILES=("file5.txt" "file6.txt")

    run print_summary "2.0.0" false false
    assert_success
    assert_output --partial "Created:   1 files"
    assert_output --partial "Updated:   2 files"
    assert_output --partial "Skipped:   1 files"
    assert_output --partial "Conflicts: 2 files"
    assert_output --partial "v2.0.0"
}
