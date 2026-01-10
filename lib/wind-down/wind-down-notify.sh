#!/bin/bash

# Wind-Down Notification Script
# Shows macOS notification at 10pm to trigger wind-down protocol

# Send notification
osascript <<EOF
display notification "Time to wrap up coding! Run 'wind-down.sh' or '/wind-down' in Claude to log your day." with title "🌙 Wind-Down Time" sound name "Glass"
EOF

# Optional: Log that notification was sent
echo "[$(date)] Wind-down notification sent" >> "$HOME/.wind-down.log"
