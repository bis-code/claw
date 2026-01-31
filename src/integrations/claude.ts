// Claude CLI integration

import { spawn, ChildProcess } from 'child_process';
import { writeFile, readFile, unlink } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { randomUUID } from 'crypto';
import { existsSync } from 'fs';

export interface ClaudeSession {
  id: string;
  pid: number;
  process: ChildProcess;
  outputFile: string;
  startedAt: Date;
  workingDir: string;
}

export interface ClaudeOutput {
  status: 'complete' | 'blocked' | 'needs_input' | 'error' | 'timeout';
  commits: string[];
  pr?: number;
  error?: string;
  blockerReason?: string;
  question?: string;
  rawOutput: string;
  exitCode?: number;
}

export const CLAW_MARKERS = {
  STATUS_COMPLETE: 'CLAW_STATUS: COMPLETE',
  STATUS_BLOCKED: 'CLAW_STATUS: BLOCKED',
  STATUS_NEEDS_INPUT: 'CLAW_STATUS: NEEDS_INPUT',
  COMMIT: 'CLAW_COMMIT:',
  PR: 'CLAW_PR:',
} as const;

export interface SpawnOptions {
  model?: 'sonnet' | 'opus' | 'haiku';
  dangerouslySkipPermissions?: boolean;
  maxTurns?: number;
  timeoutMs?: number;
  allowedTools?: string[];
}

export class ClaudeClient {
  private workingDir: string;
  private sessions: Map<string, ClaudeSession> = new Map();

  constructor(workingDir: string) {
    this.workingDir = workingDir;
  }

  /**
   * Spawn a claude CLI session
   */
  async spawn(prompt: string, options: SpawnOptions = {}): Promise<ClaudeSession> {
    const sessionId = randomUUID().slice(0, 8);
    const outputFile = join(tmpdir(), `claw-claude-${sessionId}.log`);

    // Build command arguments
    const args: string[] = ['--print', prompt];

    if (options.model) {
      args.push('--model', options.model);
    }

    if (options.dangerouslySkipPermissions) {
      args.push('--dangerously-skip-permissions');
    }

    if (options.maxTurns) {
      args.push('--max-turns', options.maxTurns.toString());
    }

    if (options.allowedTools && options.allowedTools.length > 0) {
      args.push('--allowed-tools', options.allowedTools.join(','));
    }

    // Spawn claude process
    const claudeProcess = spawn('claude', args, {
      cwd: this.workingDir,
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env },
    });

    // Collect output
    let output = '';

    claudeProcess.stdout?.on('data', (data) => {
      output += data.toString();
    });

    claudeProcess.stderr?.on('data', (data) => {
      output += data.toString();
    });

    // Write output to file periodically
    const outputInterval = setInterval(async () => {
      await writeFile(outputFile, output);
    }, 1000);

    claudeProcess.on('exit', async () => {
      clearInterval(outputInterval);
      await writeFile(outputFile, output);
    });

    const session: ClaudeSession = {
      id: sessionId,
      pid: claudeProcess.pid!,
      process: claudeProcess,
      outputFile,
      startedAt: new Date(),
      workingDir: this.workingDir,
    };

    this.sessions.set(sessionId, session);

    return session;
  }

  /**
   * Wait for claude session to complete
   */
  async waitForCompletion(session: ClaudeSession, timeoutMs: number = 600000): Promise<ClaudeOutput> {
    return new Promise((resolve) => {
      let output = '';
      let resolved = false;

      const timeout = setTimeout(() => {
        if (!resolved) {
          resolved = true;
          session.process.kill();
          resolve({
            status: 'timeout',
            commits: [],
            rawOutput: output,
            error: `Session timed out after ${timeoutMs}ms`,
          });
        }
      }, timeoutMs);

      session.process.stdout?.on('data', (data) => {
        output += data.toString();
      });

      session.process.stderr?.on('data', (data) => {
        output += data.toString();
      });

      session.process.on('exit', (code) => {
        if (!resolved) {
          resolved = true;
          clearTimeout(timeout);
          const parsed = this.parseOutput(output);
          parsed.exitCode = code ?? undefined;

          // If no explicit status but exit code is non-zero, mark as error
          if (parsed.status === 'complete' && code !== 0) {
            parsed.status = 'error';
            parsed.error = `Claude exited with code ${code}`;
          }

          resolve(parsed);
        }
      });

      session.process.on('error', (err) => {
        if (!resolved) {
          resolved = true;
          clearTimeout(timeout);
          resolve({
            status: 'error',
            commits: [],
            rawOutput: output,
            error: err.message,
          });
        }
      });
    });
  }

  /**
   * Run claude and wait for completion (convenience method)
   */
  async run(prompt: string, options: SpawnOptions = {}): Promise<ClaudeOutput> {
    const session = await this.spawn(prompt, options);
    return this.waitForCompletion(session, options.timeoutMs);
  }

  /**
   * Kill a running session
   */
  async kill(session: ClaudeSession): Promise<void> {
    if (session.process && !session.process.killed) {
      session.process.kill('SIGTERM');
    }
    this.sessions.delete(session.id);

    // Clean up output file
    if (existsSync(session.outputFile)) {
      await unlink(session.outputFile);
    }
  }

  /**
   * Get session by ID
   */
  getSession(sessionId: string): ClaudeSession | undefined {
    return this.sessions.get(sessionId);
  }

  /**
   * Read current output from a running session
   */
  async getOutput(session: ClaudeSession): Promise<string> {
    if (existsSync(session.outputFile)) {
      return readFile(session.outputFile, 'utf-8');
    }
    return '';
  }

  /**
   * Parse claude output for CLAW markers
   */
  parseOutput(rawOutput: string): ClaudeOutput {
    const output: ClaudeOutput = {
      status: 'complete',
      commits: [],
      rawOutput,
    };

    const lines = rawOutput.split('\n');
    for (const line of lines) {
      if (line.includes(CLAW_MARKERS.STATUS_COMPLETE)) {
        output.status = 'complete';
      } else if (line.includes(CLAW_MARKERS.STATUS_BLOCKED)) {
        output.status = 'blocked';
        const reason = line.split(CLAW_MARKERS.STATUS_BLOCKED)[1]?.trim();
        if (reason) output.blockerReason = reason;
      } else if (line.includes(CLAW_MARKERS.STATUS_NEEDS_INPUT)) {
        output.status = 'needs_input';
        const question = line.split(CLAW_MARKERS.STATUS_NEEDS_INPUT)[1]?.trim();
        if (question) output.question = question;
      } else if (line.includes(CLAW_MARKERS.COMMIT)) {
        const commit = line.split(CLAW_MARKERS.COMMIT)[1]?.trim();
        if (commit) output.commits.push(commit);
      } else if (line.includes(CLAW_MARKERS.PR)) {
        const prNum = line.split(CLAW_MARKERS.PR)[1]?.trim();
        if (prNum) output.pr = parseInt(prNum, 10);
      }
    }

    return output;
  }

  /**
   * Generate context prompt for a story
   */
  generateStoryPrompt(story: { title: string; scope: string[]; repos: string[] }, featureContext?: string): string {
    return `# Claw Session Context

## You Are Working On

**Story:** ${story.title}
${featureContext ? `**Feature:** ${featureContext}` : ''}

## Scope

${story.scope.map(s => `- ${s}`).join('\n')}

## Instructions

1. Implement the story following TDD
2. Commit your changes with conventional commit format
3. When done, output: \`CLAW_STATUS: COMPLETE\`
4. If blocked, output: \`CLAW_STATUS: BLOCKED <reason>\`
5. If you need input, output: \`CLAW_STATUS: NEEDS_INPUT <question>\`
6. For each commit, output: \`CLAW_COMMIT: <hash> <message>\`
7. If you create a PR, output: \`CLAW_PR: <number>\`

## Constraints

- Follow existing code patterns
- Write tests first (TDD)
- Use conventional commits
`;
  }
}
