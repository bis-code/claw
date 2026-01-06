#!/usr/bin/env bats
# Tests for agent prompts and roster

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

# Agent Prompt Tests
@test "get_agent_prompt: returns senior-dev prompt" {
    run get_agent_prompt "senior-dev"
    assert_success
    assert_output --partial "Senior Developer"
}

@test "get_agent_prompt: returns product prompt" {
    run get_agent_prompt "product"
    assert_success
    assert_output --partial "Product Manager"
}

@test "get_agent_prompt: returns cto prompt" {
    run get_agent_prompt "cto"
    assert_success
    assert_output --partial "CTO"
}

@test "get_agent_prompt: returns qa prompt" {
    run get_agent_prompt "qa"
    assert_success
    assert_output --partial "QA"
}

@test "get_agent_prompt: returns ux prompt" {
    run get_agent_prompt "ux"
    assert_success
    assert_output --partial "UX"
}

@test "get_agent_prompt: returns security prompt" {
    run get_agent_prompt "security"
    assert_success
    assert_output --partial "Security"
}

@test "get_agent_prompt: returns gameplay-programmer prompt" {
    run get_agent_prompt "gameplay-programmer"
    assert_success
    assert_output --partial "Gameplay Programmer"
}

@test "get_agent_prompt: returns systems-programmer prompt" {
    run get_agent_prompt "systems-programmer"
    assert_success
    assert_output --partial "Systems Programmer"
}

@test "get_agent_prompt: returns tools-programmer prompt" {
    run get_agent_prompt "tools-programmer"
    assert_success
    assert_output --partial "Tools Programmer"
}

@test "get_agent_prompt: returns technical-artist prompt" {
    run get_agent_prompt "technical-artist"
    assert_success
    assert_output --partial "Technical Artist"
}

@test "get_agent_prompt: returns data-scientist prompt" {
    run get_agent_prompt "data-scientist"
    assert_success
    assert_output --partial "Data Scientist"
}

@test "get_agent_prompt: returns mlops prompt" {
    run get_agent_prompt "mlops"
    assert_success
    assert_output --partial "MLOps"
}

@test "get_agent_prompt: returns api-designer prompt" {
    run get_agent_prompt "api-designer"
    assert_success
    assert_output --partial "API Designer"
}

@test "get_agent_prompt: returns docs prompt" {
    run get_agent_prompt "docs"
    assert_success
    assert_output --partial "Documentation"
}

@test "get_agent_prompt: returns auditor prompt" {
    run get_agent_prompt "auditor"
    assert_success
    assert_output --partial "Auditor"
}

@test "get_agent_prompt: returns mobile-specialist prompt" {
    run get_agent_prompt "mobile-specialist"
    assert_success
    assert_output --partial "Mobile"
}

@test "get_agent_prompt: returns desktop-specialist prompt" {
    run get_agent_prompt "desktop-specialist"
    assert_success
    assert_output --partial "Desktop"
}

@test "get_agent_prompt: handles unknown agent" {
    run get_agent_prompt "unknown-agent"
    assert_success
    assert_output --partial "Unknown agent"
}

# Orchestrator Tests
@test "get_orchestrator_prompt: returns synthesis prompt" {
    run get_orchestrator_prompt
    assert_success
    assert_output --partial "synthesizing"
}

@test "get_debate_prompt: returns debate prompt with agent name" {
    run get_debate_prompt "senior-dev"
    assert_success
    assert_output --partial "senior-dev"
}

# Agent Listing Tests
@test "list_agents: shows all agent categories" {
    run list_agents
    assert_success
    assert_output --partial "General"
    assert_output --partial "Game"
    assert_output --partial "Specialized"
}

@test "list_agents: includes all general agents" {
    run list_agents
    assert_success
    assert_output --partial "senior-dev"
    assert_output --partial "product"
    assert_output --partial "cto"
    assert_output --partial "qa"
    assert_output --partial "ux"
    assert_output --partial "security"
}

@test "list_agents: includes game agents" {
    run list_agents
    assert_success
    assert_output --partial "gameplay-programmer"
    assert_output --partial "systems-programmer"
    assert_output --partial "tools-programmer"
    assert_output --partial "technical-artist"
}

# Agent Type Mapping Tests
@test "get_agents_for_type: game-godot returns game agents" {
    run get_agents_for_type "game-godot"
    assert_success
    assert_output --partial "gameplay-programmer"
    assert_output --partial "systems-programmer"
}

@test "get_agents_for_type: web3 returns security agents" {
    run get_agents_for_type "web3"
    assert_success
    assert_output --partial "security"
    assert_output --partial "auditor"
}

@test "get_agents_for_type: data-ml returns ML agents" {
    run get_agents_for_type "data-ml"
    assert_success
    assert_output --partial "data-scientist"
    assert_output --partial "mlops"
}

@test "get_agents_for_type: api returns backend agents" {
    run get_agents_for_type "api"
    assert_success
    assert_output --partial "senior-dev"
    assert_output --partial "security"
}

@test "get_agents_for_type: mobile returns mobile agents" {
    run get_agents_for_type "mobile"
    assert_success
    assert_output --partial "mobile-specialist"
}

@test "get_agents_for_type: cli returns CLI agents" {
    run get_agents_for_type "cli"
    assert_success
    assert_output --partial "senior-dev"
    assert_output --partial "docs"
}

# Note: claw agents CLI tests removed - simplified claw no longer has agents subcommand
# The agent functions are still available via lib/agents.sh for /brainstorm command
