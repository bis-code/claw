#!/usr/bin/env bash
#
# release.sh - Create a new release of claw
#
# Usage:
#   ./scripts/release.sh <version>
#   ./scripts/release.sh 0.4.1
#
# This script will:
#   1. Update VERSION in bin/claw
#   2. Create a git tag
#   3. Push the tag (triggering CI release)
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check arguments
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 0.4.1"
    exit 1
fi

VERSION="$1"
TAG="v${VERSION}"

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format${NC}"
    echo "Version must be in format: X.Y.Z (e.g., 0.4.1)"
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo -e "${YELLOW}Warning: Not on main branch (current: $CURRENT_BRANCH)${NC}"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for uncommitted changes
if ! git -C "$PROJECT_ROOT" diff --quiet; then
    echo -e "${RED}Error: You have uncommitted changes${NC}"
    echo "Please commit or stash them before releasing"
    exit 1
fi

# Check if tag already exists
if git -C "$PROJECT_ROOT" tag -l "$TAG" | grep -q "$TAG"; then
    echo -e "${RED}Error: Tag $TAG already exists${NC}"
    exit 1
fi

echo -e "${GREEN}Creating release ${TAG}${NC}"
echo ""

# Update VERSION in bin/claw
echo "Updating VERSION in bin/claw..."
sed -i '' "s/^VERSION=\".*\"/VERSION=\"${VERSION}\"/" "$PROJECT_ROOT/bin/claw"

# Verify the change
NEW_VERSION=$(grep '^VERSION=' "$PROJECT_ROOT/bin/claw" | cut -d'"' -f2)
if [[ "$NEW_VERSION" != "$VERSION" ]]; then
    echo -e "${RED}Error: Failed to update VERSION${NC}"
    exit 1
fi

# Commit the version bump
echo "Committing version bump..."
git -C "$PROJECT_ROOT" add bin/claw
git -C "$PROJECT_ROOT" commit --no-gpg-sign -m "chore: bump version to ${VERSION}"

# Create annotated tag
echo "Creating tag ${TAG}..."
git -C "$PROJECT_ROOT" tag -a "$TAG" -m "Release ${TAG}"

# Push
echo "Pushing to origin..."
git -C "$PROJECT_ROOT" push origin main
git -C "$PROJECT_ROOT" push origin "$TAG"

echo ""
echo -e "${GREEN}✓ Release ${TAG} created and pushed!${NC}"
echo ""
echo "The GitHub Actions workflow will now:"
echo "  1. Run tests"
echo "  2. Create release tarball"
echo "  3. Create GitHub release"
echo "  4. Update homebrew-tap formula"
echo ""
echo "Monitor progress at:"
echo "  https://github.com/bis-code/claude-code-setup/actions"
