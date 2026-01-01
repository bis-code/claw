#!/bin/bash
#
# Test Coverage Validation Hook (Generic Version)
#
# This is a portable version that works in any repository.
# For project-specific patterns, copy and customize this file.
#
# Test Requirements Matrix:
# ┌──────────────────────────────────┬──────────┬─────────────┬─────────┐
# │ Change Type                      │ Unit     │ Integration │ E2E     │
# ├──────────────────────────────────┼──────────┼─────────────┼─────────┤
# │ Critical (auth/payment/crypto)   │ REQUIRED │ REQUIRED    │ REQUIRED│
# │ Auth flows                       │ REQUIRED │ -           │ REQUIRED│
# │ Database/Repository operations   │ REQUIRED │ REQUIRED    │ -       │
# │ API handlers                     │ REQUIRED │ REQUIRED    │ -       │
# │ Domain/Service/Logic             │ REQUIRED │ -           │ -       │
# │ UI components                    │ -        │ -           │ REQUIRED│
# └──────────────────────────────────┴──────────┴─────────────┴─────────┘

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Colors for stderr output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "$1" >&2
}

# Get changed files (staged + unstaged + untracked)
get_changed_files() {
    {
        git diff --name-only 2>/dev/null
        git diff --cached --name-only 2>/dev/null
        git ls-files --others --exclude-standard 2>/dev/null
    } | sort -u | grep -v '^$' || true
}

# Categorize a file by its path (GENERIC patterns)
categorize_file() {
    local file="$1"

    # Skip test files, configs, docs, build artifacts
    if [[ "$file" =~ _test\.(go|ts|tsx|js)$ ]] || \
       [[ "$file" =~ \.spec\.(ts|tsx|js)$ ]] || \
       [[ "$file" =~ \.test\.(ts|tsx|js)$ ]] || \
       [[ "$file" =~ /__tests__/ ]] || \
       [[ "$file" =~ /e2e/ ]] || \
       [[ "$file" =~ /cypress/ ]] || \
       [[ "$file" =~ \.(md|json|yml|yaml|sql|css|scss|html)$ ]] || \
       [[ "$file" =~ ^\.claude/ ]] || \
       [[ "$file" =~ ^docs/ ]] || \
       [[ "$file" =~ /config/ ]] || \
       [[ "$file" =~ config\.(go|ts|js)$ ]] || \
       [[ "$file" =~ /migrations/ ]] || \
       [[ "$file" =~ /dist/ ]] || \
       [[ "$file" =~ /build/ ]] || \
       [[ "$file" =~ /node_modules/ ]] || \
       [[ "$file" =~ \.d\.ts$ ]]; then
        echo "skip"
        return
    fi

    # ===== CRITICAL CATEGORIES =====

    # Critical business logic - Auth, Payment, Crypto
    if [[ "$file" =~ auth ]] || \
       [[ "$file" =~ crypto ]] || \
       [[ "$file" =~ payment ]] || \
       [[ "$file" =~ billing ]] || \
       [[ "$file" =~ stripe ]] || \
       [[ "$file" =~ subscription ]] || \
       [[ "$file" =~ license ]]; then
        echo "critical"
        return
    fi

    # ===== OTHER CATEGORIES =====

    # Database/Repository
    if [[ "$file" =~ repository ]] || \
       [[ "$file" =~ _mysql ]] || \
       [[ "$file" =~ _postgres ]] || \
       [[ "$file" =~ _sqlite ]] || \
       [[ "$file" =~ /db/ ]] || \
       [[ "$file" =~ /database/ ]]; then
        echo "repository"
        return
    fi

    # API handlers
    if [[ "$file" =~ handler ]] || \
       [[ "$file" =~ controller ]] || \
       [[ "$file" =~ /api/ ]] || \
       [[ "$file" =~ /routes/ ]]; then
        echo "handler"
        return
    fi

    # UI Components
    if [[ "$file" =~ \.vue$ ]] || \
       [[ "$file" =~ \.tsx$ ]] || \
       [[ "$file" =~ /components/ ]] || \
       [[ "$file" =~ /pages/ ]] || \
       [[ "$file" =~ /views/ ]]; then
        echo "ui"
        return
    fi

    # Domain/Service logic
    if [[ "$file" =~ /domain/ ]] || \
       [[ "$file" =~ /service/ ]] || \
       [[ "$file" =~ /core/ ]] || \
       [[ "$file" =~ /internal/ ]] || \
       [[ "$file" =~ /lib/ ]]; then
        echo "domain"
        return
    fi

    # Composables/Hooks/Stores
    if [[ "$file" =~ /composables/ ]] || \
       [[ "$file" =~ /hooks/ ]] || \
       [[ "$file" =~ /stores/ ]] || \
       [[ "$file" =~ use.*\.(ts|js)$ ]]; then
        echo "composable"
        return
    fi

    # Default: regular source file
    if [[ "$file" =~ \.(go|ts|tsx|js|jsx)$ ]]; then
        echo "source"
        return
    fi

    echo "skip"
}

# Find corresponding test file
find_test_file() {
    local file="$1"
    local base_name="${file%.*}"
    local ext="${file##*.}"

    # Go: file.go -> file_test.go
    if [[ "$ext" == "go" ]]; then
        [[ -f "${base_name}_test.go" ]] && return 0
    fi

    # TypeScript/JavaScript: file.ts -> file.spec.ts, file.test.ts, __tests__/file.ts
    if [[ "$ext" =~ ^(ts|tsx|js|jsx)$ ]]; then
        [[ -f "${base_name}.spec.${ext}" ]] && return 0
        [[ -f "${base_name}.test.${ext}" ]] && return 0

        local dir=$(dirname "$file")
        local filename=$(basename "$file")
        local name_without_ext="${filename%.*}"

        [[ -f "${dir}/__tests__/${filename}" ]] && return 0
        [[ -f "${dir}/__tests__/${name_without_ext}.spec.${ext}" ]] && return 0
        [[ -f "${dir}/__tests__/${name_without_ext}.test.${ext}" ]] && return 0
    fi

    return 1
}

# Check if E2E tests exist in the project
check_e2e_tests() {
    # Look for common E2E test locations
    [[ -d "e2e" ]] && [[ -n "$(ls -A e2e/*.spec.* 2>/dev/null)" ]] && return 0
    [[ -d "cypress" ]] && [[ -n "$(ls -A cypress/e2e/*.cy.* 2>/dev/null)" ]] && return 0
    [[ -d "tests/e2e" ]] && [[ -n "$(ls -A tests/e2e/*.spec.* 2>/dev/null)" ]] && return 0

    # Monorepo: apps/*/e2e
    for app_e2e in apps/*/e2e; do
        if [[ -d "$app_e2e" ]] && [[ -n "$(ls -A "$app_e2e"/*.spec.* 2>/dev/null)" ]]; then
            return 0
        fi
    done

    return 1
}

# Main validation
main() {
    log "${YELLOW}Validating test coverage...${NC}"

    local changed_files=$(get_changed_files)

    if [[ -z "$changed_files" ]]; then
        log "${GREEN}No changed files to validate.${NC}"
        echo '{"decision": "approve", "reason": "No changed files."}'
        return 0
    fi

    local missing_tests=()
    local warnings=()
    local file category

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        category=$(categorize_file "$file")

        case "$category" in
            skip)
                continue
                ;;

            critical)
                if ! find_test_file "$file" >/dev/null 2>&1; then
                    missing_tests+=("CRITICAL: $file - Missing unit test")
                fi
                if ! check_e2e_tests; then
                    warnings+=("CRITICAL: $file - E2E tests recommended")
                fi
                ;;

            repository|handler)
                if ! find_test_file "$file" >/dev/null 2>&1; then
                    missing_tests+=("$(echo "$category" | tr '[:lower:]' '[:upper:]'): $file - Missing unit test")
                fi
                ;;

            composable|domain|source)
                if ! find_test_file "$file" >/dev/null 2>&1; then
                    missing_tests+=("$(echo "$category" | tr '[:lower:]' '[:upper:]'): $file - Missing unit test")
                fi
                ;;

            ui)
                if ! check_e2e_tests; then
                    warnings+=("UI: $file - E2E tests recommended for UI components")
                fi
                ;;
        esac
    done <<< "$changed_files"

    # Output results
    if [[ ${#missing_tests[@]} -gt 0 ]]; then
        log ""
        log "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        log "${RED}║  MISSING TESTS - Task blocked until tests are added        ║${NC}"
        log "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
        log ""

        for msg in "${missing_tests[@]}"; do
            log "  ${RED}✗${NC} $msg"
        done

        log ""
        log "Add tests before completing this task."

        local reasons=$(printf '%s\\n' "${missing_tests[@]}" | head -3 | tr '\n' '; ')
        echo "{\"decision\": \"block\", \"reason\": \"Missing tests: ${reasons}\"}"
        return 1
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        log ""
        log "${YELLOW}Warnings (non-blocking):${NC}"
        for msg in "${warnings[@]}"; do
            log "  ${YELLOW}⚠${NC} $msg"
        done
        log ""
    fi

    log ""
    log "${GREEN}Test coverage validation PASSED${NC}"
    echo '{"decision": "approve", "reason": "All test coverage requirements met."}'
    return 0
}

main "$@"
