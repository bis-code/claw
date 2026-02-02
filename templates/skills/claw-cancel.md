# /claw-cancel

Cancel the current Claw autonomous loop.

## Usage

```
/claw-cancel
/claw-cancel "reason for stopping"
```

## What It Does

1. Removes `.claw-autonomous` state file
2. Allows normal session exit
3. Preserves `.claw-session.md` for later resumption

## When to Use

- Need to review code before continuing
- Want to take a break
- Found an issue that needs manual intervention
- Want to switch to a different task

## After Canceling

The session state remains in `.claw-session.md`. You can resume later with:

```
/claw-run --auto    # Continue in autonomous mode
/claw-run           # Continue in interactive mode
```

## Implementation

When this skill is invoked:

1. Check if `.claw-autonomous` exists
2. If yes, delete it and confirm: "Autonomous loop cancelled. Session preserved."
3. If no, inform: "No active autonomous loop."

```bash
rm -f .claw-autonomous
echo "Claw autonomous loop cancelled."
```
