#!/bin/bash

# Wind-Down Check - Shows terminal warning if coding after 10pm
# Source this in your .zshrc or .bashrc

wind_down_check() {
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    local today=$(date +%Y-%m-%d)
    local daily_note="$HOME/Documents/Obsidian/Daily/$today.md"

    # Dynamic cutoff: 8:30pm on gym days, 10pm otherwise
    local cutoff_hour=22
    local cutoff_minute=0
    local cutoff_label="10pm"

    # Check if gym is planned today
    if [[ -f "$daily_note" ]] && grep -q "🏋️ Gym Schedule" "$daily_note"; then
        if grep -q "Planned: Yes" "$daily_note"; then
            cutoff_hour=20
            cutoff_minute=30
            cutoff_label="8:30pm (gym day)"
        fi
    fi

    local early_morning=6

    # Check if past cutoff time
    local past_cutoff=false
    if (( current_hour > cutoff_hour || current_hour < early_morning )); then
        past_cutoff=true
    elif (( current_hour == cutoff_hour && current_minute >= cutoff_minute )); then
        past_cutoff=true
    fi

    if [[ "$past_cutoff" == "true" ]]; then
        echo ""
        echo -e "\033[1;31m╔════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[1;31m║  ⏰  CODING CUTOFF TIME PASSED  ⏰                 ║\033[0m"
        echo -e "\033[1;31m║                                                    ║\033[0m"
        echo -e "\033[1;31m║  It's past ${cutoff_label}! Consider wrapping up.           ║\033[0m"
        echo -e "\033[1;31m║                                                    ║\033[0m"
        echo -e "\033[1;33m║  💡 Run: wind-down.sh                             ║\033[0m"
        echo -e "\033[1;33m║  💡 Or in Claude: /wind-down                      ║\033[0m"
        echo -e "\033[1;31m╚════════════════════════════════════════════════════╝\033[0m"
        echo ""

        # Check if wind-down was already completed today
        if [[ -f "$daily_note" ]] && grep -q "Wind-down time:" "$daily_note"; then
            echo -e "\033[0;32m✅ Today's wind-down already logged\033[0m"
            echo -e "\033[0;33m   View: $daily_note\033[0m"
            echo ""
        else
            echo -e "\033[0;31m❌ You haven't logged today's work yet!\033[0m"
            echo ""
        fi
    fi
}

# Export the function so it can be used in shell profiles
export -f wind_down_check 2>/dev/null || true
