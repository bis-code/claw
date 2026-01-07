#!/usr/bin/env bats
# TDD Tests for project-based multi-repo management

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

setup() {
    TMP_DIR=$(mktemp -d -t claw-test-XXXXXX)
    export TMP_DIR
    export CLAW_HOME="$TMP_DIR/claw-home"
    export PROJECTS_DIR="$CLAW_HOME/projects"
    mkdir -p "$CLAW_HOME"

    # Source the projects module
    [[ -f "$PROJECT_ROOT/lib/projects.sh" ]] && source "$PROJECT_ROOT/lib/projects.sh"
}

teardown() {
    rm -rf "$TMP_DIR"
}

# ============================================================================
# project create
# ============================================================================

@test "project: create creates project directory" {
    run project_create "test-project"
    assert_success
    assert [ -d "$PROJECTS_DIR/test-project" ]
}

@test "project: create creates config.json" {
    project_create "test-project"
    assert [ -f "$PROJECTS_DIR/test-project/config.json" ]
}

@test "project: create stores name in config" {
    project_create "test-project"

    run jq -r '.name' "$PROJECTS_DIR/test-project/config.json"
    assert_output "test-project"
}

@test "project: create stores description" {
    project_create "test-project" "My test project description"

    run jq -r '.description' "$PROJECTS_DIR/test-project/config.json"
    assert_output "My test project description"
}

@test "project: create initializes empty repos array" {
    project_create "test-project"

    run jq '.repos | length' "$PROJECTS_DIR/test-project/config.json"
    assert_output "0"
}

@test "project: create fails if project already exists" {
    project_create "test-project"

    run project_create "test-project"
    assert_failure
    assert_output --partial "already exists"
}

@test "project: create stores creation timestamp" {
    project_create "test-project"

    run jq -r '.created' "$PROJECTS_DIR/test-project/config.json"
    assert_success
    # Should be ISO 8601 format
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]
}

# ============================================================================
# project_exists
# ============================================================================

@test "project: exists returns true for existing project" {
    project_create "test-project"

    run project_exists "test-project"
    assert_success
}

@test "project: exists returns false for non-existent project" {
    run project_exists "nonexistent"
    assert_failure
}

# ============================================================================
# project add-repo
# ============================================================================

@test "project: add-repo adds local folder to project" {
    project_create "test-project"

    # Create a mock git repo
    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    run project_add_repo "$TMP_DIR/my-repo" --project test-project
    assert_success
    assert_output --partial "Added to project"
}

@test "project: add-repo stores repo path" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    project_add_repo "$TMP_DIR/my-repo" --project test-project

    run jq -r '.repos[0].path' "$PROJECTS_DIR/test-project/config.json"
    assert_output "$TMP_DIR/my-repo"
}

@test "project: add-repo auto-detects repo name from folder" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-awesome-repo"
    cd "$TMP_DIR/my-awesome-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    project_add_repo "$TMP_DIR/my-awesome-repo" --project test-project

    run jq -r '.repos[0].name' "$PROJECTS_DIR/test-project/config.json"
    assert_output "my-awesome-repo"
}

@test "project: add-repo extracts GitHub remote" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/myorg/myrepo.git"

    project_add_repo "$TMP_DIR/my-repo" --project test-project

    run jq -r '.repos[0].github' "$PROJECTS_DIR/test-project/config.json"
    assert_output "myorg/myrepo"
}

@test "project: add-repo supports SSH GitHub URLs" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "git@github.com:myorg/myrepo.git"

    project_add_repo "$TMP_DIR/my-repo" --project test-project

    run jq -r '.repos[0].github' "$PROJECTS_DIR/test-project/config.json"
    assert_output "myorg/myrepo"
}

@test "project: add-repo creates marker file in repo" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    project_add_repo "$TMP_DIR/my-repo" --project test-project

    assert [ -f "$TMP_DIR/my-repo/.claw/project.json" ]
}

@test "project: add-repo marker file contains project name" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    project_add_repo "$TMP_DIR/my-repo" --project test-project

    run jq -r '.project' "$TMP_DIR/my-repo/.claw/project.json"
    assert_output "test-project"
}

@test "project: add-repo fails for non-git directory" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/not-a-repo"

    run project_add_repo "$TMP_DIR/not-a-repo" --project test-project
    assert_failure
    assert_output --partial "Not a git repository"
}

@test "project: add-repo fails for non-existent directory" {
    project_create "test-project"

    run project_add_repo "$TMP_DIR/does-not-exist" --project test-project
    assert_failure
    assert_output --partial "not found"
}

@test "project: add-repo fails for non-existent project" {
    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    run project_add_repo "$TMP_DIR/my-repo" --project nonexistent
    assert_failure
    assert_output --partial "does not exist"
}

@test "project: add-repo is idempotent (no duplicates)" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    project_add_repo "$TMP_DIR/my-repo" --project test-project
    project_add_repo "$TMP_DIR/my-repo" --project test-project
    project_add_repo "$TMP_DIR/my-repo" --project test-project

    run jq '.repos | length' "$PROJECTS_DIR/test-project/config.json"
    assert_output "1"
}

@test "project: add-repo can add multiple repos" {
    project_create "test-project"

    # Create multiple mock repos
    for i in 1 2 3; do
        mkdir -p "$TMP_DIR/repo$i"
        cd "$TMP_DIR/repo$i"
        git init -q
        git remote add origin "https://github.com/owner/repo$i.git"
        project_add_repo "$TMP_DIR/repo$i" --project test-project
    done

    run jq '.repos | length' "$PROJECTS_DIR/test-project/config.json"
    assert_output "3"
}

@test "project: add-repo allows custom name via --name" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    project_add_repo "$TMP_DIR/my-repo" --project test-project --name "custom-name"

    run jq -r '.repos[0].name' "$PROJECTS_DIR/test-project/config.json"
    assert_output "custom-name"
}

# ============================================================================
# project detection
# ============================================================================

@test "project: detect_project_from_path finds project from marker" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"
    project_add_repo "$TMP_DIR/my-repo" --project test-project

    run detect_project_from_path "$TMP_DIR/my-repo"
    assert_success
    assert_output "test-project"
}

@test "project: detect_project_from_path returns empty for non-project dir" {
    mkdir -p "$TMP_DIR/random-dir"

    run detect_project_from_path "$TMP_DIR/random-dir"
    assert_success
    assert_output ""
}

@test "project: get_current_project uses pwd" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"
    project_add_repo "$TMP_DIR/my-repo" --project test-project

    cd "$TMP_DIR/my-repo"
    run get_current_project
    assert_success
    assert_output "test-project"
}

# ============================================================================
# project remove-repo
# ============================================================================

@test "project: remove-repo removes repo from project config" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"
    project_add_repo "$TMP_DIR/my-repo" --project test-project

    project_remove_repo "$TMP_DIR/my-repo" "test-project"

    run jq '.repos | length' "$PROJECTS_DIR/test-project/config.json"
    assert_output "0"
}

@test "project: remove-repo deletes marker file" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"
    project_add_repo "$TMP_DIR/my-repo" --project test-project

    assert [ -f "$TMP_DIR/my-repo/.claw/project.json" ]

    project_remove_repo "$TMP_DIR/my-repo" "test-project"

    assert [ ! -f "$TMP_DIR/my-repo/.claw/project.json" ]
}

# ============================================================================
# project list
# ============================================================================

@test "project: list shows no projects message when empty" {
    run project_list
    assert_success
    assert_output --partial "No projects configured"
}

@test "project: list shows all projects" {
    project_create "project1"
    project_create "project2"
    project_create "project3"

    run project_list
    assert_success
    assert_output --partial "project1"
    assert_output --partial "project2"
    assert_output --partial "project3"
}

@test "project: list shows repo count per project" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/repo1"
    cd "$TMP_DIR/repo1"
    git init -q
    git remote add origin "https://github.com/owner/repo1.git"
    project_add_repo "$TMP_DIR/repo1" --project test-project

    mkdir -p "$TMP_DIR/repo2"
    cd "$TMP_DIR/repo2"
    git init -q
    git remote add origin "https://github.com/owner/repo2.git"
    project_add_repo "$TMP_DIR/repo2" --project test-project

    run project_list
    assert_output --partial "2 repos"
}

@test "project: list marks current project" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"
    project_add_repo "$TMP_DIR/my-repo" --project test-project

    cd "$TMP_DIR/my-repo"
    run project_list
    assert_output --partial "current"
}

# ============================================================================
# project show
# ============================================================================

@test "project: show displays project details" {
    project_create "test-project" "A test project"

    run project_show "test-project"
    assert_success
    assert_output --partial "test-project"
    assert_output --partial "A test project"
}

@test "project: show displays all repos" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/repo1"
    cd "$TMP_DIR/repo1"
    git init -q
    git remote add origin "https://github.com/owner/repo1.git"
    project_add_repo "$TMP_DIR/repo1" --project test-project

    run project_show "test-project"
    assert_output --partial "repo1"
    assert_output --partial "owner/repo1"
}

@test "project: show auto-detects current project" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"
    project_add_repo "$TMP_DIR/my-repo" --project test-project

    cd "$TMP_DIR/my-repo"
    run project_show
    assert_success
    assert_output --partial "test-project"
}

@test "project: show fails for non-existent project" {
    run project_show "nonexistent"
    assert_failure
    assert_output --partial "not found"
}

# ============================================================================
# get_project_repos
# ============================================================================

@test "project: get_project_repos returns all repo paths" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/repo1"
    cd "$TMP_DIR/repo1"
    git init -q
    git remote add origin "https://github.com/owner/repo1.git"
    project_add_repo "$TMP_DIR/repo1" --project test-project

    mkdir -p "$TMP_DIR/repo2"
    cd "$TMP_DIR/repo2"
    git init -q
    git remote add origin "https://github.com/owner/repo2.git"
    project_add_repo "$TMP_DIR/repo2" --project test-project

    run get_project_repos "test-project"
    assert_success
    assert_output --partial "$TMP_DIR/repo1"
    assert_output --partial "$TMP_DIR/repo2"
}

# ============================================================================
# get_project_github_repos
# ============================================================================

@test "project: get_project_github_repos returns GitHub repo names" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/repo1"
    cd "$TMP_DIR/repo1"
    git init -q
    git remote add origin "https://github.com/myorg/backend.git"
    project_add_repo "$TMP_DIR/repo1" --project test-project

    mkdir -p "$TMP_DIR/repo2"
    cd "$TMP_DIR/repo2"
    git init -q
    git remote add origin "https://github.com/myorg/frontend.git"
    project_add_repo "$TMP_DIR/repo2" --project test-project

    run get_project_github_repos "test-project"
    assert_success
    assert_output --partial "myorg/backend"
    assert_output --partial "myorg/frontend"
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "project: handles relative paths correctly" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/my-repo"
    cd "$TMP_DIR/my-repo"
    git init -q
    git remote add origin "https://github.com/owner/repo.git"

    cd "$TMP_DIR"
    run project_add_repo "./my-repo" --project test-project
    assert_success

    # Should store absolute path
    run jq -r '.repos[0].path' "$PROJECTS_DIR/test-project/config.json"
    assert_output "$TMP_DIR/my-repo"
}

@test "project: handles repo without GitHub remote" {
    project_create "test-project"

    mkdir -p "$TMP_DIR/local-only"
    cd "$TMP_DIR/local-only"
    git init -q
    # No remote set

    run project_add_repo "$TMP_DIR/local-only" --project test-project
    assert_success

    # GitHub should be empty
    run jq -r '.repos[0].github' "$PROJECTS_DIR/test-project/config.json"
    assert_output ""
}

@test "project: auto-detects project when adding repo from within project" {
    project_create "test-project"

    # First add a repo to establish project context
    mkdir -p "$TMP_DIR/first-repo"
    cd "$TMP_DIR/first-repo"
    git init -q
    git remote add origin "https://github.com/owner/first.git"
    project_add_repo "$TMP_DIR/first-repo" --project test-project

    # Now create a second repo and try to add from within first-repo
    mkdir -p "$TMP_DIR/second-repo"
    cd "$TMP_DIR/second-repo"
    git init -q
    git remote add origin "https://github.com/owner/second.git"

    # Add from within first-repo context (simulating cwd detection)
    cd "$TMP_DIR/first-repo"
    run project_add_repo "$TMP_DIR/second-repo"
    assert_success

    run jq '.repos | length' "$PROJECTS_DIR/test-project/config.json"
    assert_output "2"
}

# ============================================================================
# handle_project_command (CLI interface)
# ============================================================================

@test "project: handle_project_command create works" {
    run handle_project_command create test-proj
    assert_success
    assert_output --partial "Created project"
}

@test "project: handle_project_command list works" {
    project_create "test-project"

    run handle_project_command list
    assert_success
    assert_output --partial "test-project"
}

@test "project: handle_project_command show works" {
    project_create "test-project" "description"

    run handle_project_command show test-project
    assert_success
    assert_output --partial "test-project"
}

@test "project: handle_project_command help shows usage" {
    run handle_project_command --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "claw project create"
    assert_output --partial "claw project add-repo"
}
