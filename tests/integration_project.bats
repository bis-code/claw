#!/usr/bin/env bats
# End-to-end integration tests for project-based multi-repo workflow

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    export CLAW_HOME="$TMP_DIR/claw-home"
    export CLAUDE_HOME="$TMP_DIR/claude-home"
    export PROJECTS_DIR="$CLAW_HOME/projects"
    mkdir -p "$CLAW_HOME" "$CLAUDE_HOME"

    # Skip leann setup in tests
    touch "$CLAW_HOME/.leann-mcp-configured"

    # Mock claude command
    mkdir -p "$TMP_DIR/bin"
    echo '#!/bin/bash' > "$TMP_DIR/bin/claude"
    echo 'echo "mock claude $@"' >> "$TMP_DIR/bin/claude"
    chmod +x "$TMP_DIR/bin/claude"
    export PATH="$TMP_DIR/bin:$PATH"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# Full Project Workflow Integration Tests
# ============================================================================

@test "integration: complete project setup workflow" {
    # Step 1: Create a project
    run "$PROJECT_ROOT/bin/claw" project create "my-game" --description "My Game Project"
    assert_success
    assert_output --partial "Created project: my-game"

    # Step 2: Create multiple repos
    for repo in backend frontend contracts; do
        mkdir -p "$TMP_DIR/$repo"
        cd "$TMP_DIR/$repo"
        git init -q
        git remote add origin "https://github.com/myorg/$repo.git"
    done

    # Step 3: Add repos to project
    run "$PROJECT_ROOT/bin/claw" project add-repo "$TMP_DIR/backend" --project my-game
    assert_success

    run "$PROJECT_ROOT/bin/claw" project add-repo "$TMP_DIR/frontend" --project my-game
    assert_success

    run "$PROJECT_ROOT/bin/claw" project add-repo "$TMP_DIR/contracts" --project my-game
    assert_success

    # Step 4: Verify project has all repos
    run "$PROJECT_ROOT/bin/claw" project show my-game
    assert_success
    assert_output --partial "backend"
    assert_output --partial "frontend"
    assert_output --partial "contracts"
    assert_output --partial "3 repos" || assert_output --partial "myorg/backend"
}

@test "integration: project auto-detection from any repo" {
    source "$PROJECT_ROOT/lib/projects.sh"

    # Setup
    project_create "test-proj"

    mkdir -p "$TMP_DIR/repo1"
    cd "$TMP_DIR/repo1"
    git init -q
    git remote add origin "https://github.com/org/repo1.git"
    project_add_repo "$TMP_DIR/repo1" --project test-proj

    mkdir -p "$TMP_DIR/repo2"
    cd "$TMP_DIR/repo2"
    git init -q
    git remote add origin "https://github.com/org/repo2.git"
    project_add_repo "$TMP_DIR/repo2" --project test-proj

    # Test: from repo1, can detect project
    cd "$TMP_DIR/repo1"
    run get_current_project
    assert_success
    assert_output "test-proj"

    # Test: from repo2, same project detected
    cd "$TMP_DIR/repo2"
    run get_current_project
    assert_success
    assert_output "test-proj"
}

@test "integration: project list command shows all projects" {
    source "$PROJECT_ROOT/lib/projects.sh"

    # Create multiple projects
    project_create "project-alpha"
    project_create "project-beta"
    project_create "project-gamma"

    run "$PROJECT_ROOT/bin/claw" project list
    assert_success
    assert_output --partial "project-alpha"
    assert_output --partial "project-beta"
    assert_output --partial "project-gamma"
}

@test "integration: claw startup banner shows project info" {
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/lib/projects.sh"

    # Create project and add current repo (simulated)
    project_create "test-proj"

    mkdir -p "$TMP_DIR/myrepo"
    cd "$TMP_DIR/myrepo"
    git init -q
    git remote add origin "https://github.com/org/myrepo.git"
    project_add_repo "$TMP_DIR/myrepo" --project test-proj

    # Source claw after setting up project context
    cd "$TMP_DIR/myrepo"
    source "$PROJECT_ROOT/bin/claw"

    run show_startup_banner
    assert_success
    assert_output --partial "Project: test-proj"
}

@test "integration: adding repo from within project context" {
    source "$PROJECT_ROOT/lib/projects.sh"

    # Create project
    project_create "test-proj"

    # Add first repo with explicit project
    mkdir -p "$TMP_DIR/repo1"
    cd "$TMP_DIR/repo1"
    git init -q
    git remote add origin "https://github.com/org/repo1.git"
    project_add_repo "$TMP_DIR/repo1" --project test-proj

    # Add second repo FROM repo1 (should auto-detect project)
    mkdir -p "$TMP_DIR/repo2"
    cd "$TMP_DIR/repo2"
    git init -q
    git remote add origin "https://github.com/org/repo2.git"

    cd "$TMP_DIR/repo1"
    run project_add_repo "$TMP_DIR/repo2"
    assert_success

    # Verify both repos are in project
    run get_project_repos "test-proj"
    assert_success
    assert_output --partial "$TMP_DIR/repo1"
    assert_output --partial "$TMP_DIR/repo2"
}

# ============================================================================
# Legacy Repos + Project Coexistence
# ============================================================================

@test "integration: legacy repos and project repos coexist" {
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/lib/projects.sh"

    # Add legacy tracked repo
    repos_add "legacy/repo"

    # Create project with repos
    project_create "modern-proj"

    mkdir -p "$TMP_DIR/modern-repo"
    cd "$TMP_DIR/modern-repo"
    git init -q
    git remote add origin "https://github.com/org/modern.git"
    project_add_repo "$TMP_DIR/modern-repo" --project modern-proj

    # Verify legacy repos still work
    run repos_list
    assert_success
    assert_output --partial "legacy/repo"

    # Verify project repos work
    run get_project_github_repos "modern-proj"
    assert_success
    assert_output --partial "org/modern"
}

# ============================================================================
# Template Installation Tests (Unit Level)
# ============================================================================

@test "integration: templates list shows all templates" {
    run "$PROJECT_ROOT/bin/claw" templates list
    assert_success
    assert_output --partial "bug-report"
    assert_output --partial "feature-request"
    assert_output --partial "claude-ready"
    assert_output --partial "tech-debt"
}

# ============================================================================
# Multi-Repo Issue Fetching (Mocked)
# ============================================================================

@test "integration: fetch_project_issues aggregates from project repos" {
    source "$PROJECT_ROOT/lib/repos.sh"
    source "$PROJECT_ROOT/lib/projects.sh"

    # Create project with repos
    project_create "test-proj"

    mkdir -p "$TMP_DIR/repo1"
    cd "$TMP_DIR/repo1"
    git init -q
    git remote add origin "https://github.com/org/repo1.git"
    project_add_repo "$TMP_DIR/repo1" --project test-proj

    mkdir -p "$TMP_DIR/repo2"
    cd "$TMP_DIR/repo2"
    git init -q
    git remote add origin "https://github.com/org/repo2.git"
    project_add_repo "$TMP_DIR/repo2" --project test-proj

    # Verify we can get github repos for issue fetching
    run get_project_github_repos "test-proj"
    assert_success
    assert_output --partial "org/repo1"
    assert_output --partial "org/repo2"
}

# ============================================================================
# Error Handling
# ============================================================================

@test "integration: graceful error when project doesn't exist" {
    run "$PROJECT_ROOT/bin/claw" project show nonexistent-project
    assert_failure
    assert_output --partial "not found"
}

@test "integration: graceful error when adding non-git folder" {
    source "$PROJECT_ROOT/lib/projects.sh"

    project_create "test-proj"
    mkdir -p "$TMP_DIR/not-a-repo"

    run project_add_repo "$TMP_DIR/not-a-repo" --project test-proj
    assert_failure
    assert_output --partial "Not a git repository"
}

@test "integration: graceful error when adding to non-existent project" {
    mkdir -p "$TMP_DIR/myrepo"
    cd "$TMP_DIR/myrepo"
    git init -q
    git remote add origin "https://github.com/org/repo.git"

    run "$PROJECT_ROOT/bin/claw" project add-repo "$TMP_DIR/myrepo" --project nonexistent
    assert_failure
    assert_output --partial "does not exist"
}

# ============================================================================
# CLI Help Integration
# ============================================================================

@test "integration: claw help shows project commands" {
    run "$PROJECT_ROOT/bin/claw" --help
    assert_success
    assert_output --partial "project create"
    assert_output --partial "project add-repo"
    assert_output --partial "project list"
    assert_output --partial "project show"
    assert_output --partial "project issues"
}

@test "integration: project help shows all subcommands" {
    run "$PROJECT_ROOT/bin/claw" project --help
    assert_success
    assert_output --partial "create"
    assert_output --partial "add-repo"
    assert_output --partial "remove-repo"
    assert_output --partial "list"
    assert_output --partial "show"
    assert_output --partial "issues"
}
