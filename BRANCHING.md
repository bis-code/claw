# Branching & Release Strategy

This project uses a **develop/main** branching strategy with automated releases via release-please.

## Branch Overview

### `develop` (Default Branch)
- **Purpose:** Integration branch for daily development
- **PRs target:** `develop`
- **Protection:** Require CI to pass
- **Who pushes:** All contributors

### `main` (Production Branch)
- **Purpose:** Production-ready code, triggers releases
- **PRs target:** `main` (only from `develop`)
- **Protection:** Require PR, require CI, no force push
- **Who pushes:** Maintainers only (via release PRs)

---

## Daily Development Workflow

### 1. Create Feature Branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
```

### 2. Make Changes & Push
```bash
# Make your changes
git add .
git commit -m "feat(scope): add new feature"
git push origin feature/my-feature
```

### 3. Create PR Targeting `develop`
```bash
gh pr create --base develop --head feature/my-feature
```

### 4. Merge to Develop
Once CI passes and approved:
```bash
gh pr merge <PR#> --squash
```

**Result:** Feature is now on `develop`, but **not released yet**.

---

## Release Workflow

### When to Release

Choose your cadence:
- **Weekly:** Every Friday
- **Milestone-based:** After completing a feature set
- **On-demand:** When you have changes ready to ship

### How to Release

#### Step 1: Create Release PR
```bash
# Check what's new on develop
git log main..develop --oneline

# Create PR from develop to main
gh pr create --base main --head develop \
  --title "chore: prepare release" \
  --body "Ready to release: <list key features>"
```

#### Step 2: Merge develop → main
```bash
gh pr merge <PR#>
```

#### Step 3: Release-Please Creates Release PR
Within minutes, release-please will automatically:
- Create PR titled `chore(main): release X.Y.Z`
- Update VERSION in `bin/claw`
- Generate CHANGELOG.md from conventional commits

#### Step 4: Review & Merge Release PR
```bash
# Review the generated changelog
gh pr view <release-PR#>

# Merge to trigger release
gh pr merge <release-PR#>
```

#### Step 5: Automatic Release 🎉
When you merge the release PR:
- Git tag created (e.g., `v1.4.2`)
- GitHub release published with changelog
- Homebrew formula automatically updated

#### Step 6: Sync Back to Develop
```bash
git checkout develop
git pull origin develop
git merge main  # Get version bump back
git push origin develop
```

---

## Commit Message Format

Use conventional commits for automatic changelog generation:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types
- `feat`: New feature (triggers minor bump)
- `fix`: Bug fix (triggers patch bump)
- `docs`: Documentation changes
- `chore`: Maintenance tasks
- `refactor`: Code refactoring
- `test`: Adding tests
- `ci`: CI/CD changes

### Examples
```bash
feat(cli): add --verbose flag
fix(parser): handle edge case in URL parsing
docs(readme): update installation instructions
chore(deps): upgrade dependencies
```

---

## Version Bumping

Release-please automatically determines version bumps:

| Commit Type | Version Change | Example |
|-------------|----------------|---------|
| `feat:` | Minor bump | 1.4.0 → 1.5.0 |
| `fix:` | Patch bump | 1.4.0 → 1.4.1 |
| `BREAKING CHANGE:` | Major bump | 1.4.0 → 2.0.0 |
| `chore:`, `docs:`, etc. | No bump | - |

---

## Testing Before Release (Optional)

Before creating an official release, you can test the Homebrew installation using a release candidate (RC):

### Create RC for Testing
1. Go to: **Actions** → **Staging Release (Test Homebrew)** → **Run workflow**
2. Enter RC version (e.g., `1.4.2-rc1`)
3. Workflow creates:
   - RC tag on `develop` branch
   - Pre-release on GitHub
   - Tarball with SHA256

### Test the RC
```bash
# Install RC version
brew uninstall claw 2>/dev/null || true
brew install https://github.com/bis-code/claw/releases/download/v1.4.2-rc1/claw-1.4.2-rc1.tar.gz

# Test functionality
claw --version
claw --help
# ... test your features ...

# Uninstall RC
brew uninstall claw
```

### After Testing
If tests pass:
```bash
# Clean up RC
gh release delete v1.4.2-rc1 --yes
git push origin :v1.4.2-rc1

# Proceed with official release (Steps 1-6 above)
```

If tests fail:
- Fix issues on `develop`
- Create new RC (e.g., `1.4.2-rc2`)
- Test again

---

## Example Timeline

**Monday - Thursday: Development**
```
PR #101: feat(search): add fuzzy search → develop ✓
PR #102: fix(parser): handle UTF-8 → develop ✓
PR #103: feat(export): add JSON export → develop ✓
```

**Friday: Release Day**
```
1. Create PR: develop → main
2. Merge it
3. Release-please creates: PR "chore(main): release 1.5.0"
4. Merge release PR
5. v1.5.0 published automatically! 🎉
```

**Next Week:**
```
Continue development on develop...
```

---

## Branch Protection Rules

### `develop`
- ✅ Require status checks (CI) to pass
- ✅ Require branches to be up to date
- ❌ Allow force push (for rebasing if needed)

### `main`
- ✅ Require pull request
- ✅ Require status checks (CI) to pass
- ✅ Require branches to be up to date
- ❌ Block force push
- ✅ Require linear history

---

## FAQ

**Q: Can I push directly to develop?**  
A: No, always create a PR. This ensures CI runs and code is reviewed.

**Q: How often should we release?**  
A: Up to you! Weekly is common, but milestone-based works too.

**Q: What if I need a hotfix in production?**  
A: Create a branch from `main`, fix the issue, PR to `main`, follow release process.

**Q: Do I need to update the version number manually?**  
A: No! Release-please does this automatically when you merge the release PR.

**Q: What if release-please creates the wrong version?**  
A: You can edit the release PR before merging. The version is determined by your commit messages (feat = minor, fix = patch).

---

## Getting Help

- **Release-Please Docs:** https://github.com/googleapis/release-please
- **Conventional Commits:** https://www.conventionalcommits.org/
- **Questions?** Open an issue with the `question` label
