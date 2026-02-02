#!/bin/bash
# Claw Autonomous Loop - Stop Hook
# Similar to Ralph Wiggum's approach: intercepts exit and re-injects prompt

CLAW_STATE_FILE=".claw-autonomous"
SESSION_FILE=".claw-session.md"

# Check if we're in autonomous mode
if [[ ! -f "$CLAW_STATE_FILE" ]]; then
  # Not in autonomous mode, allow normal exit
  exit 0
fi

# Read state
source "$CLAW_STATE_FILE"

# Check iteration count
CURRENT_ITERATION=${CLAW_ITERATION:-0}
MAX_ITERATIONS=${CLAW_MAX_ITERATIONS:-50}

if [[ $CURRENT_ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Claw: Max iterations ($MAX_ITERATIONS) reached. Stopping."
  rm -f "$CLAW_STATE_FILE"
  exit 0
fi

# Check if session is complete (all items marked done)
if [[ -f "$SESSION_FILE" ]]; then
  # Count incomplete items (lines with "- [ ]")
  INCOMPLETE=$(grep -c '\- \[ \]' "$SESSION_FILE" 2>/dev/null || echo "0")

  if [[ "$INCOMPLETE" == "0" ]]; then
    echo "Claw: All items complete! Session finished."
    rm -f "$CLAW_STATE_FILE"
    exit 0
  fi
fi

# Check for blocker file (user intervention needed)
if [[ -f ".claw-blocked" ]]; then
  echo "Claw: Blocker detected. Stopping for user review."
  rm -f "$CLAW_STATE_FILE"
  exit 0
fi

# Increment iteration
NEW_ITERATION=$((CURRENT_ITERATION + 1))
cat > "$CLAW_STATE_FILE" << EOF
CLAW_ITERATION=$NEW_ITERATION
CLAW_MAX_ITERATIONS=$MAX_ITERATIONS
CLAW_PROMPT="$CLAW_PROMPT"
EOF

# Output continuation prompt (this gets fed back to Claude)
echo ""
echo "---"
echo "Claw Autonomous Mode - Iteration $NEW_ITERATION/$MAX_ITERATIONS"
echo ""
echo "Continue working on the session. Read .claw-session.md to see current progress."
echo "Find the first incomplete item (- [ ]) and continue from there."
echo ""
echo "If blocked, create .claw-blocked file with the reason."
echo "When all items are complete, the loop will exit automatically."
echo "---"
echo ""
echo "$CLAW_PROMPT"

# Exit code 2 blocks the exit and re-injects the prompt
exit 2
