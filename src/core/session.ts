// Session management - running Claude sessions for stories

export interface SessionConfig {
  storyId: string;
  featureId: string;
  repo: string;
  context: string;
  maxIterations?: number;
  timeoutMinutes?: number;
}

export interface SessionResult {
  status: 'complete' | 'blocked' | 'timeout' | 'error';
  iterations: number;
  commits: string[];
  pr?: number;
  error?: string;
  blockerReason?: string;
}

export interface SessionState {
  id: string;
  storyId: string;
  featureId: string;
  startedAt: Date;
  iteration: number;
  lastError?: string;
  filesChanged: string[];
}

export class SessionRunner {
  constructor(
    private obsidianPath: string,
    private workspacePath: string
  ) {}

  async run(config: SessionConfig): Promise<SessionResult> {
    // TODO: Spawn claude session, monitor, collect results (Epic 3)
    throw new Error('Not implemented - Epic 3');
  }

  async resume(sessionId: string): Promise<SessionResult> {
    // TODO: Resume session from Obsidian state (Story 4.4)
    throw new Error('Not implemented - Story 4.4');
  }

  async interrupt(sessionId: string, action: 'pause' | 'skip' | 'abort'): Promise<void> {
    // TODO: Handle keyboard interrupts (Story 4.1)
    throw new Error('Not implemented - Story 4.1');
  }

  async askClaude(sessionId: string, question: string): Promise<string> {
    // TODO: Ask Claude mid-session (Story 4.2)
    throw new Error('Not implemented - Story 4.2');
  }

  async pivot(sessionId: string, pivotData: any): Promise<void> {
    // TODO: Handle pivot request (Story 4.3)
    throw new Error('Not implemented - Story 4.3');
  }

  private async spawnClaude(repo: string, prompt: string): Promise<string> {
    // TODO: Actually spawn claude CLI (Story 1.5)
    throw new Error('Not implemented - Story 1.5');
  }

  private async parseOutput(output: string): Promise<{ status: string; commits: string[]; pr?: number }> {
    // TODO: Parse CLAW_STATUS markers from output (Story 1.5)
    throw new Error('Not implemented - Story 1.5');
  }
}
