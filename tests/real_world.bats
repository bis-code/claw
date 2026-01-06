#!/usr/bin/env bats
# Real-world integration tests
# Tests that claw works correctly in realistic scenarios

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
# New Project Tests - Projects with no existing Claude configuration
# ============================================================================

@test "new project: claw init on empty directory" {
    mkdir -p "$TMP_DIR/new-project"
    cd "$TMP_DIR/new-project"

    run "$PROJECT_ROOT/bin/claw" init
    assert_success

    # Should create .claude directory
    assert [ -d ".claude" ]
    assert [ -d ".claude/rules" ]
}

@test "new project: claw init creates valid CLAUDE.md for full preset" {
    mkdir -p "$TMP_DIR/new-project"
    cd "$TMP_DIR/new-project"

    "$PROJECT_ROOT/bin/claw" init --preset full

    run cat CLAUDE.md
    assert_success
    assert_output --partial "CLAUDE.md"
    assert_output --partial "Critical Rules"
}

@test "new project: claw init creates manifest.json" {
    mkdir -p "$TMP_DIR/new-project"
    cd "$TMP_DIR/new-project"

    "$PROJECT_ROOT/bin/claw" init

    # Should create manifest for version tracking
    assert [ -f ".claude/manifest.json" ]
    run cat .claude/manifest.json
    assert_output --partial "version"
    assert_output --partial "claw"
}

@test "new project: claw init on React project auto-detects type" {
    mkdir -p "$TMP_DIR/react-app"
    cd "$TMP_DIR/react-app"

    cat > package.json << 'EOF'
{
  "name": "my-react-app",
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  }
}
EOF

    run "$PROJECT_ROOT/bin/claw" init
    assert_success
    assert_output --partial "Auto-detected preset"
}

@test "new project: claw init on Unity project uses unity preset" {
    mkdir -p "$TMP_DIR/unity-game/Assets" "$TMP_DIR/unity-game/ProjectSettings"
    cd "$TMP_DIR/unity-game"

    run "$PROJECT_ROOT/bin/claw" init
    assert_success
    assert_output --partial "unity"
}

@test "new project: claw init on Next.js SaaS project" {
    mkdir -p "$TMP_DIR/saas-app"
    cd "$TMP_DIR/saas-app"

    cat > package.json << 'EOF'
{
  "name": "my-saas",
  "dependencies": {
    "next": "^14.0.0",
    "stripe": "^14.0.0",
    "next-auth": "^4.0.0"
  }
}
EOF

    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "saas"
}

@test "new project: claw init on Web3 project" {
    mkdir -p "$TMP_DIR/web3-app"
    cd "$TMP_DIR/web3-app"

    cat > hardhat.config.js << 'EOF'
module.exports = { solidity: "0.8.0" };
EOF

    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "web3"
}

# ============================================================================
# Existing Config Tests - Projects that already have Claude configuration
# ============================================================================

@test "existing config: claw init shows installed version" {
    mkdir -p "$TMP_DIR/existing-project/.claude"
    cd "$TMP_DIR/existing-project"

    # First init creates manifest
    "$PROJECT_ROOT/bin/claw" init --preset base

    # Second init shows installed version
    run "$PROJECT_ROOT/bin/claw" init --preset base
    assert_success
    assert_output --partial "Installed:"
}

@test "existing config: claw init --force overwrites" {
    mkdir -p "$TMP_DIR/existing-project/.claude/commands"
    echo "old content" > "$TMP_DIR/existing-project/.claude/commands/old.md"
    cd "$TMP_DIR/existing-project"

    run "$PROJECT_ROOT/bin/claw" init --force
    assert_success

    # Should still have .claude directory
    assert [ -d ".claude" ]
}

@test "existing config: claw upgrade works on initialized project" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    # First init
    "$PROJECT_ROOT/bin/claw" init

    # Then upgrade
    run "$PROJECT_ROOT/bin/claw" upgrade
    assert_success
}

@test "existing config: claw detect works on configured project" {
    mkdir -p "$TMP_DIR/project/.claude"
    cd "$TMP_DIR/project"

    cat > package.json << 'EOF'
{"dependencies": {"express": "^4.0.0"}}
EOF

    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "api"
}

@test "existing config: claw agents works after init" {
    mkdir -p "$TMP_DIR/project"
    cd "$TMP_DIR/project"

    "$PROJECT_ROOT/bin/claw" init

    run "$PROJECT_ROOT/bin/claw" agents list
    assert_success
    assert_output --partial "Recommended"
}

# ============================================================================
# Monorepo Tests
# ============================================================================

@test "monorepo: claw detect identifies pnpm workspace" {
    mkdir -p "$TMP_DIR/monorepo/packages/web" "$TMP_DIR/monorepo/packages/api"
    cd "$TMP_DIR/monorepo"

    cat > pnpm-workspace.yaml << 'EOF'
packages:
  - 'packages/*'
EOF

    cat > packages/web/package.json << 'EOF'
{"name": "@myapp/web", "dependencies": {"react": "^18.0.0"}}
EOF

    cat > packages/api/package.json << 'EOF'
{"name": "@myapp/api", "dependencies": {"express": "^4.0.0"}}
EOF

    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "Packages:"
}

@test "monorepo: claw init works in monorepo root" {
    mkdir -p "$TMP_DIR/monorepo/packages/web"
    cd "$TMP_DIR/monorepo"

    cat > pnpm-workspace.yaml << 'EOF'
packages:
  - 'packages/*'
EOF

    run "$PROJECT_ROOT/bin/claw" init
    assert_success
    assert [ -d ".claude" ]
}

# ============================================================================
# Multi-Repo Tests
# ============================================================================

@test "multi-repo: claw works from any sibling repo" {
    mkdir -p "$TMP_DIR/projects/myapp-frontend" "$TMP_DIR/projects/myapp-backend"
    git -C "$TMP_DIR/projects/myapp-frontend" init -q
    git -C "$TMP_DIR/projects/myapp-backend" init -q
    cd "$TMP_DIR/projects/myapp-frontend"

    run "$PROJECT_ROOT/bin/claw" multi-repo detect
    assert_success
    assert_output --partial "myapp-backend"
}

@test "multi-repo: claw init works in multi-repo setup" {
    mkdir -p "$TMP_DIR/projects/frontend" "$TMP_DIR/projects/backend"
    git -C "$TMP_DIR/projects/frontend" init -q
    cd "$TMP_DIR/projects/frontend"

    run "$PROJECT_ROOT/bin/claw" init
    assert_success
    assert [ -d ".claude" ]
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "edge case: claw works in deeply nested directory" {
    mkdir -p "$TMP_DIR/a/b/c/d/e/project"
    cd "$TMP_DIR/a/b/c/d/e/project"

    run "$PROJECT_ROOT/bin/claw" init
    assert_success
}

@test "edge case: claw works with spaces in path" {
    mkdir -p "$TMP_DIR/My Project/src"
    cd "$TMP_DIR/My Project"

    run "$PROJECT_ROOT/bin/claw" init
    assert_success
    assert [ -d ".claude" ]
}

@test "edge case: claw works with unicode in path" {
    mkdir -p "$TMP_DIR/项目/src"
    cd "$TMP_DIR/项目"

    run "$PROJECT_ROOT/bin/claw" init
    assert_success
}

@test "edge case: claw detect handles missing package.json gracefully" {
    mkdir -p "$TMP_DIR/empty-project"
    cd "$TMP_DIR/empty-project"

    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "unknown"
}

@test "edge case: claw detect handles malformed package.json" {
    mkdir -p "$TMP_DIR/broken-project"
    cd "$TMP_DIR/broken-project"

    echo "not valid json" > package.json

    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
}

# ============================================================================
# Full Workflow Tests
# ============================================================================

@test "workflow: complete setup flow for new React project" {
    mkdir -p "$TMP_DIR/react-app"
    cd "$TMP_DIR/react-app"

    cat > package.json << 'EOF'
{"name": "my-app", "dependencies": {"react": "^18.0.0"}}
EOF

    # Step 1: Detect
    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "web"

    # Step 2: Init
    run "$PROJECT_ROOT/bin/claw" init
    assert_success

    # Step 3: Check agents
    run "$PROJECT_ROOT/bin/claw" agents list
    assert_success

    # Step 4: Check LEANN status
    run "$PROJECT_ROOT/bin/claw" leann status
    assert_success
}

@test "workflow: complete setup flow for existing project with .claude" {
    mkdir -p "$TMP_DIR/existing-app/.claude/commands"
    cd "$TMP_DIR/existing-app"

    echo "# Existing command" > .claude/commands/custom.md

    cat > package.json << 'EOF'
{"name": "existing-app", "dependencies": {"express": "^4.0.0"}}
EOF

    # Init should work and create manifest
    run "$PROJECT_ROOT/bin/claw" init
    assert_success
    assert_output --partial "Setup Complete"

    # Custom command should still exist (not managed by claw)
    assert [ -f ".claude/commands/custom.md" ]

    # Detect should work
    run "$PROJECT_ROOT/bin/claw" detect
    assert_success
    assert_output --partial "api"
}

@test "workflow: upgrade preserves custom files" {
    mkdir -p "$TMP_DIR/project/.claude/commands"
    cd "$TMP_DIR/project"

    # Create custom command
    echo "# My custom command" > .claude/commands/my-custom.md

    # Init first
    "$PROJECT_ROOT/bin/claw" init --force

    # Add custom content after init
    echo "# Another custom" > .claude/commands/another.md

    # Upgrade
    run "$PROJECT_ROOT/bin/claw" upgrade
    assert_success

    # Custom files should still exist
    assert [ -f ".claude/commands/another.md" ]
}
