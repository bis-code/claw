# Local Testing Guide

Quick methods to test claw locally without releases.

## Quick Start (Makefile) ⭐

The easiest way to test locally:

```bash
make dev        # Enable dev mode
vim bin/claw    # Make changes
claw --version  # Test instantly!
make test       # Quick validation
```

**All make commands:**
- `make dev` - Enable dev mode
- `make test` - Quick test
- `make test-full` - Run all tests
- `make install` - Install normally (disables dev mode)
- `make clean` - Remove all

---

## Method 1: Direct Installation from Local Directory (Fastest) ⚡

Test the exact code you're working on:

```bash
# From your project directory
./install.sh

# Or test with bash directly
bash install.sh

# Verify
claw --version
which claw  # Should show ~/.local/bin/claw or similar
```

**Pros:**
- Instant feedback
- No git commits needed
- Tests actual install script

**Cons:**
- Doesn't test Homebrew formula

---

## Method 2: Homebrew from Local Directory 🍺

Create a local formula pointing to your working directory:

### One-Time Setup
```bash
# Create local tap directory
mkdir -p $(brew --prefix)/Homebrew/Library/Taps/local/homebrew-test
cd $(brew --prefix)/Homebrew/Library/Taps/local/homebrew-test
mkdir -p Formula

# Create local formula
cat > Formula/claw.rb <<'FORMULA'
class Claw < Formula
  desc "Command Line Automated Workflow - Claude Code CLI tool"
  homepage "https://github.com/bis-code/claw"
  url "file:///Users/baicoianuionut/som/personal-projects/claude-code-setup"
  version "1.4.2-local"

  def install
    bin.install "bin/claw"
    prefix.install "lib"
    prefix.install "templates"
    prefix.install "install.sh"
  end

  test do
    system "#{bin}/claw", "--version"
  end
end
FORMULA
```

**Note:** Change the `url` path to your actual project path!

### Test Installation
```bash
# Uninstall production version
brew uninstall claw 2>/dev/null || true

# Install from local
brew install local/test/claw

# Test
claw --version
claw --help

# After changes, reinstall
brew reinstall local/test/claw

# When done, remove local version
brew uninstall claw
```

**Pros:**
- Tests Homebrew installation
- Can iterate quickly with `brew reinstall`
- No network needed

**Cons:**
- One-time setup required
- Need to update path in formula

---

## Method 3: Test Install Script Only (Super Fast) 🚀

Just test if the install script works:

```bash
# Create test install location
export INSTALL_DIR="/tmp/claw-test"
mkdir -p "$INSTALL_DIR"

# Run install script with custom location
bash install.sh

# Test
export PATH="$INSTALL_DIR:$PATH"
claw --version

# Cleanup
rm -rf "$INSTALL_DIR"
```

---

## Method 4: Symlink for Live Updates (Development Mode) 🔗

Install once, then all changes are immediately available:

```bash
# Install claw normally first
./install.sh

# Replace installed version with symlink
rm -rf ~/.local/bin/claw
ln -s /Users/baicoianuionut/som/personal-projects/claude-code-setup/bin/claw ~/.local/bin/claw

# Also symlink lib directory
rm -rf ~/.claude/lib
ln -s /Users/baicoianuionut/som/personal-projects/claude-code-setup/lib ~/.claude/lib
```

**Now any changes you make are instantly available!**

```bash
# Edit code
vim bin/claw

# Test immediately (no reinstall needed!)
claw --version
```

**To remove dev mode:**
```bash
rm ~/.local/bin/claw
rm ~/.claude/lib
./install.sh  # Reinstall normally
```

**Pros:**
- ⚡ INSTANT feedback
- No reinstall needed
- Perfect for development

**Cons:**
- Need to remember to unlink before releases

---

## Method 5: Docker Testing (Bonus) 🐳

Test in a clean environment without affecting your system:

```bash
# Create Dockerfile
cat > Dockerfile.test <<'DOCKER'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    git \
    bash \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /claw
COPY . .

RUN bash install.sh

CMD ["claw", "--version"]
DOCKER

# Build and test
docker build -f Dockerfile.test -t claw-test .
docker run --rm claw-test

# Test commands
docker run --rm claw-test claw --help
```

---

## Recommended Development Workflow

### Daily Development (Fastest)
**Use Method 4:** Symlink for live updates
```bash
# Setup once
ln -s $(pwd)/bin/claw ~/.local/bin/claw
ln -s $(pwd)/lib ~/.claude/lib

# Edit, test, repeat - NO reinstall needed!
vim bin/claw
claw --version  # ⚡ instant
```

### Before Creating PR (Thorough)
**Use Method 1:** Clean install from script
```bash
# Remove symlinks
rm ~/.local/bin/claw ~/.claude/lib

# Test clean install
./install.sh
claw --version
```

### Before Release to Main (Full Test)
**Use Method 2:** Homebrew local formula
```bash
brew reinstall local/test/claw
claw --version
```

### After Merging to Main (Production Test)
**Use RC Workflow:** Create v1.4.2-rc1 and test with real Homebrew

---

## Quick Reference

| Method | Speed | Completeness | Use Case |
|--------|-------|--------------|----------|
| 1. Direct install | ⚡⚡⚡ | Medium | Quick functionality test |
| 2. Homebrew local | ⚡⚡ | High | Test formula before release |
| 3. Script only | ⚡⚡⚡ | Low | Test install script logic |
| 4. Symlink | ⚡⚡⚡⚡ | Medium | Active development |
| 5. Docker | ⚡ | Very High | Clean environment test |
| RC Workflow | ⚡ | Highest | Pre-release validation |

---

## Common Tasks

### Test After Making Changes
```bash
# If using symlink (Method 4)
claw --version  # Instant!

# If using direct install (Method 1)
./install.sh && claw --version

# If using Homebrew (Method 2)
brew reinstall local/test/claw && claw --version
```

### Test Specific Feature
```bash
# Test new command
claw project list

# Test with Claude session
cd /tmp/test-project
claw
```

### Test Uninstall
```bash
# Remove installation
rm -rf ~/.local/bin/claw
rm -rf ~/.claude

# Verify gone
which claw  # Should show nothing
claw  # Should error
```

### Reset to Clean State
```bash
# Remove everything
rm -rf ~/.local/bin/claw
rm -rf ~/.claude
brew uninstall claw 2>/dev/null || true

# Start fresh
./install.sh
```

---

## Pro Tips

1. **Always test in a new terminal** after installation to ensure PATH is correct

2. **Use aliases for quick testing:**
   ```bash
   # Add to ~/.zshrc or ~/.bashrc
   alias claw-dev='cd ~/som/personal-projects/claude-code-setup && ./install.sh'
   alias claw-test='claw --version && claw --help'
   ```

3. **Create a test script:**
   ```bash
   cat > test-claw.sh <<'TEST'
   #!/bin/bash
   set -e
   echo "Testing claw installation..."
   claw --version
   claw --help | grep -q "Command Line Automated Workflow"
   echo "✅ All tests passed!"
   TEST
   chmod +x test-claw.sh
   ./test-claw.sh
   ```

4. **Test in clean directory:**
   ```bash
   cd /tmp
   mkdir test-claw-$(date +%s)
   cd test-claw-*
   claw  # Test if it works outside project
   ```

