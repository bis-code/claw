#!/bin/bash

# Auto Wind-Down - Opens terminal and runs wind-down script at cutoff time
# This script checks gym plans and opens terminal at the right time

TODAY=$(date +%Y-%m-%d)
DAILY_NOTE="$HOME/Documents/Obsidian/Daily/$TODAY.md"
CURRENT_HOUR=$(date +%H)
CURRENT_MINUTE=$(date +%M)

# Determine cutoff based on gym plans
GYM_TODAY=false
if [[ -f "$DAILY_NOTE" ]] && grep -q "🏋️ Gym Schedule" "$DAILY_NOTE"; then
    if grep -q "Planned: Yes" "$DAILY_NOTE"; then
        GYM_TODAY=true
    fi
fi

# Check if wind-down already completed today
if [[ -f "$DAILY_NOTE" ]] && grep -q "Wind-down time:" "$DAILY_NOTE"; then
    # Already logged today, just show notification
    terminal-notifier \
        -title "🌙 Wind-Down" \
        -message "Wind-down already completed! ✅" \
        -sound "Glass"
    echo "[$(date)] Wind-down already completed" >> "$HOME/.wind-down.log"
    exit 0
fi

# Determine if we should send notification
# Extended window: within 1 hour of cutoff
SHOULD_NOTIFY=false
CUTOFF_MESSAGE=""

if [[ "$GYM_TODAY" == "true" ]]; then
    # Gym day: 8:30pm-9:30pm window
    if (( CURRENT_HOUR == 20 && CURRENT_MINUTE >= 30 )) || (( CURRENT_HOUR == 21 )); then
        SHOULD_NOTIFY=true
        CUTOFF_MESSAGE="Time to wind down before gym! 💪"
    fi
else
    # No gym: 10pm-11pm window
    if (( CURRENT_HOUR == 22 )) || (( CURRENT_HOUR == 23 )); then
        SHOULD_NOTIFY=true
        CUTOFF_MESSAGE="Time to wind down for the night! 🌙"
    fi
fi

if [[ "$SHOULD_NOTIFY" == "true" ]]; then
    # Send rich notification with action button
    terminal-notifier \
        -title "🌙 Wind-Down Time" \
        -message "$CUTOFF_MESSAGE" \
        -sound "Glass" \
        -actions "Open iTerm,Remind Me Later" \
        -execute "$HOME/bin/wind-down-iterm.sh" \
        -timeout 300

    echo "[$(date)] Wind-down notification with action sent" >> "$HOME/.wind-down.log"
fi
