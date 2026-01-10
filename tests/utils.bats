#!/usr/bin/env bats
# Unit tests for utility functions

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper.bash'

# Source utils.sh
source "$PROJECT_ROOT/lib/utils.sh"

@test "parse_github_repo: parses HTTPS URL with .git suffix" {
    run parse_github_repo "https://github.com/owner/repo.git"
    assert_success
    assert_output "owner/repo"
}

@test "parse_github_repo: parses HTTPS URL without .git suffix" {
    run parse_github_repo "https://github.com/owner/repo"
    assert_success
    assert_output "owner/repo"
}

@test "parse_github_repo: parses SSH URL with .git suffix" {
    run parse_github_repo "git@github.com:owner/repo.git"
    assert_success
    assert_output "owner/repo"
}

@test "parse_github_repo: parses SSH URL without .git suffix" {
    run parse_github_repo "git@github.com:owner/repo"
    assert_success
    assert_output "owner/repo"
}

@test "parse_github_repo: handles repo names with hyphens" {
    run parse_github_repo "https://github.com/my-org/my-repo-name.git"
    assert_success
    assert_output "my-org/my-repo-name"
}

@test "parse_github_repo: handles repo names with dots" {
    run parse_github_repo "https://github.com/owner/repo.name.git"
    assert_success
    assert_output "owner/repo.name"
}

@test "parse_github_repo: returns empty for non-GitHub URLs" {
    run parse_github_repo "https://gitlab.com/owner/repo.git"
    assert_success
    assert_output ""
}

@test "parse_github_repo: returns empty for invalid format" {
    run parse_github_repo "not-a-url"
    assert_success
    assert_output ""
}

@test "parse_github_repo: returns empty for empty input" {
    run parse_github_repo ""
    assert_success
    assert_output ""
}

@test "parse_github_repo: handles github.com URLs with www prefix" {
    run parse_github_repo "https://www.github.com/owner/repo.git"
    assert_success
    assert_output "owner/repo"
}
