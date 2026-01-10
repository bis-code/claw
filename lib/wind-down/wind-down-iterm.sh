#!/bin/bash

# Wind-Down iTerm Launcher
# Opens iTerm2 and runs the wind-down script

osascript <<'EOF'
tell application "iTerm"
    activate

    -- Create new window
    create window with default profile

    -- Run wind-down script in the new window
    tell current session of current window
        write text "$HOME/bin/wind-down.sh"
    end tell
end tell
EOF

echo "[$(date)] iTerm opened with wind-down script" >> "$HOME/.wind-down.log"
