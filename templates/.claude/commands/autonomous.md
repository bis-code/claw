---
description: Execute tasks from queue with TDD, feedback loops, and blocker handling (internal - called by /auto)
args: [--init] [--import] [--run] [--status] [--checkpoint NAME]
---

# /autonomous - Autonomous Task Executor

> **Note:** This is an internal command called by `/auto`. For everyday use, run `/auto` instead.

Run tasks from the queue with automatic test feedback, checkpointing, and blocker resolution.

## Usage

```bash
/autonomous --init                    # Initialize task queue
/autonomous --import                  # Import GitHub issues as tasks
/autonomous --run                     # Execute next task from queue
/autonomous --run --loop              # Execute all tasks until done
/autonomous --status                  # Show queue status
/autonomous --checkpoint "milestone"  # Create checkpoint before risky work
```

## How It Works

The autonomous executor uses these modules:

| Module | Purpose |
|--------|---------|
| `executor.sh` | Task queue management, execution loop |
| `feedback.sh` | Test detection, error parsing, retry logic |
| `blocker.sh` | Blocker detection, auto-resolution, human intervention |
| `checkpoint.sh` | State persistence, rollback capability |

## Execution Flow

### 1. Initialize (--init)

```bash
source lib/autonomous/executor.sh
init_task_queue
```

Creates `.claude/queue.json` with empty task, completed, and failed arrays.

### 2. Import Issues (--import)

```bash
source lib/autonomous/executor.sh
import_from_github --repo OWNER/REPO --label "claude-ready"
```

Imports GitHub issues labeled `claude-ready` into the task queue.

### 3. Execute Tasks (--run)

For each task:

1. **Create checkpoint** before starting
2. **Detect test framework** (npm, pytest, cargo, go)
3. **Execute task** in TDD loop:
   - Run tests
   - If failing, parse errors and suggest fixes
   - Retry up to 3 times with feedback
4. **Handle blockers**:
   - Missing dependency → auto-install
   - Rate limit → wait and retry
   - Permission/Auth → request human help
5. **Update queue** (complete or fail task)

### 4. Status (--status)

Shows:
- Pending tasks (prioritized)
- Running task
- Completed count
- Failed count with blockers

## Integration with /plan-day

After `/plan-day` approves a plan:

```bash
# Auto-triggered by /plan-day on approval
/autonomous --init
/autonomous --import --label "in-progress"
/autonomous --run --loop
```

## Safety Features

- **Checkpoints**: Auto-created before each task
- **Max iterations**: Prevents infinite loops (default: 10)
- **Stop on failure**: Can halt on first failure with `--stop-on-failure`
- **Confidence scoring**: Skips tasks that repeatedly fail

## Example Session

```
> /autonomous --status
Queue Status:
  Pending: 3 tasks
  Running: 0
  Completed: 5
  Failed: 1

Next task: #53 Fix settings validation (high priority)

> /autonomous --run
Creating checkpoint: before-task-53
Executing: Fix settings validation
  Running tests... FAIL (2 failures)
  Parsing errors:
    - src/settings.test.ts:45 - Expected: true, Received: false
  Suggesting fix: Check return value of validateSettings()
  Retry 1/3...
  Running tests... PASS
Task completed: #53
```

## Blocker Handling

| Blocker Type | Auto-Resolution | Human Required |
|--------------|-----------------|----------------|
| Missing dependency | `npm install X` | No |
| Rate limit | Wait 60s | No |
| Network error | Retry after 5s | No |
| Permission denied | - | Yes |
| Auth failed | - | Yes |

When human intervention is needed:
1. Creates `.claude/intervention-request.json`
2. Pauses execution
3. Waits for `.claude/intervention-response.json`
4. Resumes on `{ "resolved": true }`

## Files

```
.claude/
├── queue.json              # Task queue state
├── checkpoints/            # Saved checkpoints
├── session.json            # Session persistence
├── blocker-history.json    # Blocker patterns
├── intervention-request.json   # Human help requests
└── intervention-response.json  # Human responses
```

## Source

```bash
# Load all autonomous modules
source lib/autonomous/executor.sh
source lib/autonomous/feedback.sh
source lib/autonomous/blocker.sh
source lib/autonomous/checkpoint.sh
```
