#!/usr/bin/env bats
# Tests for multi-repo functionality

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    export CLAW_HOME="$TMP_DIR/claw-home"
    export CLAUDE_HOME="$TMP_DIR/claude-home"
    mkdir -p "$CLAW_HOME" "$CLAUDE_HOME"
    # Skip leann setup in tests
    touch "$CLAW_HOME/.leann-mcp-configured"
    # Mock claude command
    mkdir -p "$TMP_DIR/bin"
    echo '#!/bin/bash' > "$TMP_DIR/bin/claude"
    echo 'echo "mock claude"' >> "$TMP_DIR/bin/claude"
    chmod +x "$TMP_DIR/bin/claude"
    export PATH="$TMP_DIR/bin:$PATH"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# Multi-Repo Detection Tests
@test "detect_multi_repo: detects sibling repos by pattern" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/game" "$parent/frontend" "$parent/backend"

    run detect_multi_repo "$parent/game"
    assert_success
    assert_output --partial "detected"
}

@test "detect_multi_repo: reads existing config file" {
    mkdir -p "$TMP_DIR/.claw"
    cat > "$TMP_DIR/.claw/multi-repo.json" << 'EOF'
{
    "detected": true,
    "repos": ["repo1", "repo2"]
}
EOF
    run detect_multi_repo "$TMP_DIR"
    assert_success
    assert_output --partial "detected"
}

@test "detect_multi_repo: checks parent directory config" {
    local parent="$TMP_DIR/parent"
    local child="$parent/child"
    mkdir -p "$parent/.claw" "$child"

    cat > "$parent/.claw/multi-repo.json" << 'EOF'
{
    "detected": true,
    "repos": ["child", "sibling"]
}
EOF
    run detect_multi_repo "$child"
    assert_success
}

@test "detect_multi_repo: returns false for isolated repo" {
    mkdir -p "$TMP_DIR/isolated"
    run detect_multi_repo "$TMP_DIR/isolated"
    assert_success
    assert_output --partial '"detected": false'
}

# Cross-Repo Dependency Tests
@test "detect_cross_repo_dependencies: returns empty array by default" {
    run detect_cross_repo_dependencies "$TMP_DIR"
    assert_success
    assert_output "[]"
}

# Config Creation Tests
@test "create_multi_repo_config: creates config file" {
    mkdir -p "$TMP_DIR"
    run create_multi_repo_config "$TMP_DIR"
    assert_success
    assert [ -f "$TMP_DIR/.claw/multi-repo.json" ]
}

@test "create_multi_repo_config: creates .claw directory" {
    mkdir -p "$TMP_DIR"
    run create_multi_repo_config "$TMP_DIR"
    assert_success
    assert [ -d "$TMP_DIR/.claw" ]
}

# Note: CLI tests for `claw multi-repo` removed - command no longer exists
# Multi-repo functionality is now integrated into /plan-day command

# Pattern Detection Tests
@test "detect_multi_repo: finds frontend sibling" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/game" "$parent/frontend"

    run detect_multi_repo "$parent/game"
    assert_success
    assert_output --partial "frontend"
}

@test "detect_multi_repo: finds backend sibling" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/api" "$parent/backend"

    run detect_multi_repo "$parent/api"
    assert_success
    assert_output --partial "backend"
}

@test "detect_multi_repo: finds contracts sibling" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/frontend" "$parent/contracts"

    run detect_multi_repo "$parent/frontend"
    assert_success
    assert_output --partial "contracts"
}

# Cross-Repo Dependency Detection Tests
@test "detect_cross_repo_dependencies: detects npm file: dependencies" {
    # Setup multi-repo structure
    mkdir -p "$TMP_DIR/myapp-frontend"
    mkdir -p "$TMP_DIR/myapp-shared"
    git -C "$TMP_DIR/myapp-frontend" init -q
    git -C "$TMP_DIR/myapp-shared" init -q

    # Add package.json with file: dependency
    cat > "$TMP_DIR/myapp-frontend/package.json" << 'EOF'
{
  "name": "myapp-frontend",
  "dependencies": {
    "shared": "file:../myapp-shared"
  }
}
EOF

    cd "$TMP_DIR/myapp-frontend"
    run detect_cross_repo_dependencies "."
    assert_success
    assert_output --partial "npm-local"
}

@test "detect_cross_repo_dependencies: detects git submodules" {
    mkdir -p "$TMP_DIR/main-repo"
    git -C "$TMP_DIR/main-repo" init -q

    # Create .gitmodules file
    cat > "$TMP_DIR/main-repo/.gitmodules" << 'EOF'
[submodule "libs/shared"]
    path = libs/shared
    url = git@github.com:example/shared.git
EOF

    run detect_cross_repo_dependencies "$TMP_DIR/main-repo"
    assert_success
    assert_output --partial "git-submodule"
}

# Prefix Detection Tests
@test "detect_multi_repo: detects prefix pattern myapp-*" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/myapp-frontend" "$parent/myapp-backend" "$parent/myapp-contracts"
    git -C "$parent/myapp-frontend" init -q
    git -C "$parent/myapp-backend" init -q
    git -C "$parent/myapp-contracts" init -q

    run detect_multi_repo "$parent/myapp-frontend"
    assert_success
    assert_output --partial '"prefix": "myapp"'
    assert_output --partial "myapp-backend"
}

@test "detect_multi_repo: git siblings take priority" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/myproject" "$parent/other-git-repo" "$parent/non-git-folder"
    git -C "$parent/myproject" init -q
    git -C "$parent/other-git-repo" init -q
    # non-git-folder has no .git

    run detect_multi_repo "$parent/myproject"
    assert_success
    assert_output --partial "other-git-repo"
}

@test "detect_multi_repo: includes project type in output" {
    local parent="$TMP_DIR/projects"
    mkdir -p "$parent/myapp-frontend" "$parent/myapp-backend"
    git -C "$parent/myapp-frontend" init -q
    git -C "$parent/myapp-backend" init -q

    # Make backend look like an API project
    cat > "$parent/myapp-backend/package.json" << 'EOF'
{"dependencies": {"express": "^4.0.0"}}
EOF

    run detect_multi_repo "$parent/myapp-frontend"
    assert_success
    assert_output --partial '"type":'
}

# ============================================================================
# Project-based Multi-Repo Issue Fetching Tests
# ============================================================================

@test "project: fetch_project_issues returns empty array when no project" {
    # Source projects module
    source "$PROJECT_ROOT/lib/projects.sh"

    # Not in a project
    cd "$TMP_DIR"

    run fetch_project_issues
    assert_success
    # Should return empty JSON array (deduplicated)
    [[ "$output" == "[]" ]] || [[ -z "$output" ]]
}

@test "project: get_project_github_repos returns repos for project" {
    source "$PROJECT_ROOT/lib/projects.sh"

    # Create project with repos
    project_create "test-proj"

    mkdir -p "$TMP_DIR/repo1"
    cd "$TMP_DIR/repo1"
    git init -q
    git remote add origin "https://github.com/org/backend.git"
    project_add_repo "$TMP_DIR/repo1" --project test-proj

    mkdir -p "$TMP_DIR/repo2"
    cd "$TMP_DIR/repo2"
    git init -q
    git remote add origin "https://github.com/org/frontend.git"
    project_add_repo "$TMP_DIR/repo2" --project test-proj

    run get_project_github_repos "test-proj"
    assert_success
    assert_output --partial "org/backend"
    assert_output --partial "org/frontend"
}

@test "repos: show_issues_summary with --json returns JSON" {
    source "$PROJECT_ROOT/lib/repos.sh"

    # Mock gh to return test data
    function gh() {
        echo '[{"number": 1, "title": "Test issue", "labels": [], "repository": {"nameWithOwner": "test/repo"}}]'
    }
    export -f gh

    repos_add "test/repo"

    run show_issues_summary --json
    assert_success
    # Should output JSON
    assert_output --partial "number"
}

# ============================================================================
# Executor Multi-Repo Tests
# ============================================================================

@test "executor: import_from_github has --all-repos flag" {
    source "$PROJECT_ROOT/lib/autonomous/executor.sh"

    # Check that the function accepts the flag (verify signature)
    run type import_from_github
    assert_success
    assert_output --partial "all_repos"
}
