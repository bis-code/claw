// Claude CLI integration

export interface ClaudeSession {
  pid: number;
  outputFile: string;
  startedAt: Date;
}

export interface ClaudeOutput {
  status: 'complete' | 'blocked' | 'needs_input';
  commits: string[];
  pr?: number;
  error?: string;
  blockerReason?: string;
  question?: string;
}

export const CLAW_MARKERS = {
  STATUS_COMPLETE: 'CLAW_STATUS: COMPLETE',
  STATUS_BLOCKED: 'CLAW_STATUS: BLOCKED',
  STATUS_NEEDS_INPUT: 'CLAW_STATUS: NEEDS_INPUT',
  COMMIT: 'CLAW_COMMIT:',
  PR: 'CLAW_PR:',
} as const;

export class ClaudeClient {
  constructor(private workingDir: string) {}

  async spawn(prompt: string, options?: { model?: string; dangerouslySkipPermissions?: boolean }): Promise<ClaudeSession> {
    // TODO: Spawn claude CLI process (Story 1.5)
    throw new Error('Not implemented - Story 1.5');
  }

  async waitForCompletion(session: ClaudeSession, timeoutMs?: number): Promise<ClaudeOutput> {
    // TODO: Wait for claude to finish, parse output (Story 1.5)
    throw new Error('Not implemented - Story 1.5');
  }

  async sendInput(session: ClaudeSession, input: string): Promise<void> {
    // TODO: Send input to running claude session (Story 4.2)
    throw new Error('Not implemented - Story 4.2');
  }

  async kill(session: ClaudeSession): Promise<void> {
    // TODO: Kill claude session (Story 4.1)
    throw new Error('Not implemented - Story 4.1');
  }

  parseOutput(rawOutput: string): ClaudeOutput {
    const output: ClaudeOutput = {
      status: 'complete',
      commits: [],
    };

    const lines = rawOutput.split('\\n');
    for (const line of lines) {
      if (line.includes(CLAW_MARKERS.STATUS_COMPLETE)) {
        output.status = 'complete';
      } else if (line.includes(CLAW_MARKERS.STATUS_BLOCKED)) {
        output.status = 'blocked';
        output.blockerReason = line.split(CLAW_MARKERS.STATUS_BLOCKED)[1]?.trim();
      } else if (line.includes(CLAW_MARKERS.STATUS_NEEDS_INPUT)) {
        output.status = 'needs_input';
        output.question = line.split(CLAW_MARKERS.STATUS_NEEDS_INPUT)[1]?.trim();
      } else if (line.includes(CLAW_MARKERS.COMMIT)) {
        output.commits.push(line.split(CLAW_MARKERS.COMMIT)[1]?.trim());
      } else if (line.includes(CLAW_MARKERS.PR)) {
        output.pr = parseInt(line.split(CLAW_MARKERS.PR)[1]?.trim(), 10);
      }
    }

    return output;
  }
}
