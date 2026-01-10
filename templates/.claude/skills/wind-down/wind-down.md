# Wind-Down Protocol

Execute the daily brain dump and coding cutoff routine.

## What This Does

1. Scans ~/work/ (work repos) and ~/som/ (personal repos) for today's commits
2. Prompts user for quick structured brain dump
3. Saves everything to Obsidian Daily Notes: ~/Documents/Obsidian/Daily/YYYY-MM-DD.md
4. Shows reminder to stop coding if after 10pm

## Execution Steps

### 1. Run the Wind-Down Script

Execute the wind-down script using Bash:

```bash
~/bin/wind-down.sh
```

**IMPORTANT**: This script is INTERACTIVE and will prompt the user for input. You should:
- Use `run_in_background: false` to allow user interaction
- NOT interrupt or cancel the script - let it complete fully
- Wait for the script to finish before responding

### 2. After Script Completes

Once the script finishes:
1. Confirm the daily note was created in Obsidian
2. Show the user the path to today's note
3. If it's after 10pm, gently remind them it's time to wrap up
4. Suggest reviewing tomorrow's priorities in the morning

### 3. Error Handling

If the script fails:
- Check that ~/bin/wind-down.sh exists and is executable
- Verify Obsidian vault path: ~/Documents/Obsidian/Daily/
- Ensure git repos exist at ~/work/ and ~/som/

## Output Format

Keep your response brief:

```
Running wind-down protocol...

[Wait for script to complete]

✅ Brain dump complete!

Daily note saved: ~/Documents/Obsidian/Daily/2026-01-09.md

Tomorrow's priorities:
- Work: [what they entered]
- Personal: [what they entered]

💡 Tip: Review these priorities when you start tomorrow.
```

If after 10pm, add:
```
⏰ It's past 10pm - time to wrap up for the night!
```

## When This Skill Is Used

- User explicitly runs `/wind-down`
- User asks to "log my day" or "brain dump"
- Optionally: At start of `/plan-day` if previous day wasn't logged
- Optionally: When Claude detects it's past 10pm and user is still coding

## Philosophy

This is an ADHD-friendly tool that:
- Makes brain dumps quick (2-3 minutes max)
- Uses structured prompts (no blank page paralysis)
- Shows immediate value (commits + priorities)
- Gentle enforcement (warnings, not blocks)
- Builds habit through consistency (every day at 10pm)
