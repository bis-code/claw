#!/bin/bash

# Wind-Down Script - Daily Brain Dump & Coding Cutoff
# Scans work and personal repos, prompts for reflection, saves to Obsidian

set -e

# Configuration
OBSIDIAN_VAULT="$HOME/Documents/Obsidian/Daily"
WORK_DIR="$HOME/work"
PERSONAL_DIR="$HOME/som"
TODAY=$(date +%Y-%m-%d)
DAILY_NOTE="$OBSIDIAN_VAULT/$TODAY.md"

# Dynamic cutoff based on gym plans
# Default: 10pm (no gym)
# Gym day: 8:30pm (before 9pm gym session)
CUTOFF_HOUR=22
CUTOFF_MINUTE=0

# Check if gym is planned today by reading daily note
if [[ -f "$DAILY_NOTE" ]] && grep -q "🏋️ Gym Schedule" "$DAILY_NOTE"; then
    if grep -q "Planned: Yes" "$DAILY_NOTE"; then
        CUTOFF_HOUR=20  # 8:30pm on gym days
        CUTOFF_MINUTE=30
    fi
fi

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Ensure Obsidian directory exists
mkdir -p "$OBSIDIAN_VAULT"

# Function to scan repos in a directory
scan_repos() {
    local base_dir=$1
    local category=$2
    local found_commits=false

    if [[ ! -d "$base_dir" ]]; then
        return
    fi

    # Find all git repos
    while IFS= read -r repo; do
        repo_name=$(basename "$repo")

        # Get today's commits
        commits=$(cd "$repo" && git log --since="midnight" --pretty=format:"  - %s (%h)" 2>/dev/null || true)

        if [[ -n "$commits" ]]; then
            if [[ "$found_commits" == false ]]; then
                echo -e "\n${BOLD}${category} Commits:${NC}"
                found_commits=true
            fi
            echo -e "${CYAN}$repo_name${NC}"
            echo "$commits"
        fi
    done < <(find "$base_dir" -name ".git" -type d -prune | sed 's|/.git$||')

    if [[ "$found_commits" == false ]]; then
        echo -e "\n${BOLD}${category} Commits:${NC}"
        echo -e "  ${YELLOW}No commits today${NC}"
    fi
}

# Function to check if it's past cutoff time
check_time() {
    current_hour=$(date +%H)
    current_minute=$(date +%M)

    # Past cutoff if: after cutoff hour OR (at cutoff hour and past cutoff minute) OR before 6am
    if (( current_hour > CUTOFF_HOUR || current_hour < 6 )); then
        return 0  # Past cutoff
    elif (( current_hour == CUTOFF_HOUR && current_minute >= CUTOFF_MINUTE )); then
        return 0  # Past cutoff
    else
        return 1  # Before cutoff
    fi
}

# Function to prompt for input with a label
prompt() {
    local label=$1
    local var_name=$2
    echo -e "\n${BOLD}${BLUE}$label${NC}"
    read -r "$var_name"
}

# Function to prompt for multiline input
prompt_multiline() {
    local label=$1
    local var_name=$2
    echo -e "\n${BOLD}${BLUE}$label${NC}"
    echo -e "${YELLOW}(Type your response, press Enter twice when done)${NC}"

    local lines=""
    local empty_count=0

    while true; do
        read -r line
        if [[ -z "$line" ]]; then
            ((empty_count++))
            if (( empty_count >= 1 )); then
                break
            fi
        else
            empty_count=0
            lines="${lines}${line}\n"
        fi
    done

    eval "$var_name=\"$lines\""
}

# Header
clear
echo -e "${BOLD}${MAGENTA}"
echo "╔════════════════════════════════════════════╗"
echo "║         🌙 WIND-DOWN PROTOCOL 🌙          ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if it's past cutoff time
if check_time; then
    if (( CUTOFF_HOUR == 20 )); then
        echo -e "${RED}${BOLD}⏰ It's past 8:30pm! Time to wrap up coding before gym.${NC}\n"
    else
        echo -e "${RED}${BOLD}⏰ It's past 10pm! Time to wrap up coding.${NC}\n"
    fi
else
    if (( CUTOFF_HOUR == 20 )); then
        echo -e "${GREEN}Running early wind-down (before 8:30pm gym cutoff)${NC}\n"
    else
        echo -e "${GREEN}Running early wind-down (before 10pm cutoff)${NC}\n"
    fi
fi

echo -e "${BOLD}Date:${NC} $TODAY"
echo -e "${BOLD}Time:${NC} $(date +%H:%M)"

# Scan work repos
echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
scan_repos "$WORK_DIR" "💼 Work"

# Scan personal repos
echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
scan_repos "$PERSONAL_DIR" "🎮 Personal"

# Brain dump prompts
echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${MAGENTA}🧠 Quick Brain Dump (2-3 min max!)${NC}"
echo -e "${YELLOW}Keep it short - just capture what's in your head${NC}"

# Work accomplishments
prompt_multiline "💼 Work done today (3 bullet points):" work_done
if [[ -z "$work_done" ]]; then
    work_done="- No work logged\n"
fi

# Personal accomplishments
prompt_multiline "🎮 Personal/Fun stuff done:" personal_done
if [[ -z "$personal_done" ]]; then
    personal_done="- No personal work logged\n"
fi

# Tomorrow priorities
prompt "📋 Tomorrow's top priority (work):" work_priority
if [[ -z "$work_priority" ]]; then
    work_priority="Not set"
fi

prompt "🎯 Tomorrow's top priority (personal):" personal_priority
if [[ -z "$personal_priority" ]]; then
    personal_priority="Not set"
fi

# Energy and focus
prompt "⚡ Energy level (1-10):" energy_level
if [[ -z "$energy_level" ]]; then
    energy_level="N/A"
fi

prompt "🧭 What's stealing focus right now:" focus_stealer
if [[ -z "$focus_stealer" ]]; then
    focus_stealer="Nothing noted"
fi

# Generate Obsidian note
echo -e "\n${BOLD}${GREEN}💾 Saving to Obsidian...${NC}"

cat > "$DAILY_NOTE" << EOF
# Daily Log - $TODAY

**Wind-down time:** $(date +%H:%M)
**Energy level:** $energy_level/10

## 💼 Work Done Today

$work_done

## 🎮 Personal Work Done Today

$personal_done

## 🎯 Tomorrow's Priorities

**Work:** $work_priority
**Personal:** $personal_priority

## 🧭 Focus & Context

**What's stealing focus:** $focus_stealer

---

## 📊 Commit Summary

### Work Repos

$(cd "$WORK_DIR" 2>/dev/null && find . -name ".git" -type d -prune | sed 's|/.git$||' | while read -r repo; do
    repo_name=$(basename "$repo")
    commits=$(cd "$repo" && git log --since="midnight" --pretty=format:"- %s (%h)" 2>/dev/null || true)
    if [[ -n "$commits" ]]; then
        echo "#### $repo_name"
        echo "$commits"
        echo ""
    fi
done || echo "No work repos found")

### Personal Repos

$(cd "$PERSONAL_DIR" 2>/dev/null && find . -name ".git" -type d -prune | sed 's|/.git$||' | while read -r repo; do
    repo_name=$(basename "$repo")
    commits=$(cd "$repo" && git log --since="midnight" --pretty=format:"- %s (%h)" 2>/dev/null || true)
    if [[ -n "$commits" ]]; then
        echo "#### $repo_name"
        echo "$commits"
        echo ""
    fi
done || echo "No personal repos found")

---

*Generated by Wind-Down Protocol 🌙*
EOF

echo -e "${GREEN}✅ Saved to: $DAILY_NOTE${NC}"

# Final message
echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if check_time; then
    echo -e "${BOLD}${RED}"
    echo "╔════════════════════════════════════════════╗"
    echo "║  ⏰  TIME TO STOP CODING  ⏰               ║"
    echo "║                                            ║"
    echo "║  Brain dumped ✅                           ║"
    echo "║  Tomorrow's priorities set ✅              ║"
    echo "║  Time to wind down for the night 🌙        ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}"
else
    echo -e "${GREEN}${BOLD}✅ Brain dump complete! You're all set.${NC}\n"
fi

echo -e "${YELLOW}Tip: Review tomorrow's priorities in the morning${NC}"
echo -e "${YELLOW}     Open Obsidian: $DAILY_NOTE${NC}\n"
