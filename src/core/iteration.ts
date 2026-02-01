// Iteration-until-green - retry logic and stuck detection

import chalk from 'chalk';
import { ClaudeClient, ClaudeOutput, SpawnOptions } from '../integrations/claude.js';
import { Story } from './feature.js';

export interface IterationConfig {
  /** Maximum iterations per story */
  maxIterations: number;
  /** Initial delay between retries in ms */
  initialDelayMs: number;
  /** Maximum delay between retries in ms */
  maxDelayMs: number;
  /** Backoff multiplier */
  backoffMultiplier: number;
  /** Errors that should not be retried */
  fatalErrors: string[];
  /** Claude model to use */
  model?: 'sonnet' | 'opus' | 'haiku';
  /** Skip permission prompts */
  dangerouslySkipPermissions?: boolean;
}

export interface IterationState {
  storyId: string;
  iteration: number;
  lastError?: string;
  lastOutput?: ClaudeOutput;
  startTime: Date;
  history: IterationAttempt[];
}

export interface IterationAttempt {
  iteration: number;
  timestamp: Date;
  status: ClaudeOutput['status'];
  error?: string;
  durationMs: number;
}

export interface IterationResult {
  success: boolean;
  iterations: number;
  finalOutput: ClaudeOutput;
  history: IterationAttempt[];
  stuckReason?: string;
}

const DEFAULT_CONFIG: IterationConfig = {
  maxIterations: 5,
  initialDelayMs: 1000,
  maxDelayMs: 30000,
  backoffMultiplier: 2,
  fatalErrors: [
    'Permission denied',
    'Authentication failed',
    'Invalid API key',
    'Rate limit exceeded',
    'User aborted',
  ],
};

export class IterationEngine {
  private claude: ClaudeClient;
  private config: IterationConfig;
  private states: Map<string, IterationState> = new Map();

  constructor(workingDir: string, config: Partial<IterationConfig> = {}) {
    this.claude = new ClaudeClient(workingDir);
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Execute a story with retry logic until green or stuck
   */
  async executeUntilGreen(
    story: Story,
    featureTitle: string,
    onProgress?: (state: IterationState) => void
  ): Promise<IterationResult> {
    const state: IterationState = {
      storyId: story.id,
      iteration: 0,
      startTime: new Date(),
      history: [],
    };
    this.states.set(story.id, state);

    let currentDelay = this.config.initialDelayMs;

    while (state.iteration < this.config.maxIterations) {
      state.iteration++;
      console.log(chalk.dim(`   Iteration ${state.iteration}/${this.config.maxIterations}`));

      const attemptStart = Date.now();
      const output = await this.runIteration(story, featureTitle, state);
      const attemptDuration = Date.now() - attemptStart;

      // Record attempt
      const attempt: IterationAttempt = {
        iteration: state.iteration,
        timestamp: new Date(),
        status: output.status,
        error: output.error || output.blockerReason,
        durationMs: attemptDuration,
      };
      state.history.push(attempt);
      state.lastOutput = output;
      state.lastError = output.error || output.blockerReason;

      // Notify progress
      if (onProgress) {
        onProgress(state);
      }

      // Check result
      if (output.status === 'complete') {
        console.log(chalk.green(`   ✓ Completed in ${state.iteration} iteration(s)`));
        return {
          success: true,
          iterations: state.iteration,
          finalOutput: output,
          history: state.history,
        };
      }

      if (output.status === 'needs_input') {
        // Can't retry - needs human input
        return {
          success: false,
          iterations: state.iteration,
          finalOutput: output,
          history: state.history,
          stuckReason: `Needs input: ${output.question}`,
        };
      }

      // Check for fatal errors
      if (this.isFatalError(output)) {
        console.log(chalk.red(`   ✗ Fatal error - won't retry: ${state.lastError}`));
        return {
          success: false,
          iterations: state.iteration,
          finalOutput: output,
          history: state.history,
          stuckReason: `Fatal error: ${state.lastError}`,
        };
      }

      // Check for stuck pattern (same error 3+ times)
      if (this.isStuck(state)) {
        console.log(chalk.yellow(`   ⚠️  Detected stuck pattern - same error repeated`));
        return {
          success: false,
          iterations: state.iteration,
          finalOutput: output,
          history: state.history,
          stuckReason: `Stuck: same error repeated (${state.lastError})`,
        };
      }

      // Wait before retry (if not last iteration)
      if (state.iteration < this.config.maxIterations) {
        console.log(chalk.dim(`   Waiting ${currentDelay}ms before retry...`));
        await this.delay(currentDelay);
        currentDelay = Math.min(
          currentDelay * this.config.backoffMultiplier,
          this.config.maxDelayMs
        );
      }
    }

    // Max iterations reached
    console.log(chalk.yellow(`   ⚠️  Max iterations (${this.config.maxIterations}) reached`));
    return {
      success: false,
      iterations: state.iteration,
      finalOutput: state.lastOutput!,
      history: state.history,
      stuckReason: `Max iterations reached: ${state.lastError || 'unknown error'}`,
    };
  }

  /**
   * Run a single iteration
   */
  private async runIteration(
    story: Story,
    featureTitle: string,
    state: IterationState
  ): Promise<ClaudeOutput> {
    // Build prompt with iteration context
    let prompt = this.claude.generateStoryPrompt(
      {
        title: story.title,
        scope: story.scope,
        repos: story.repos,
      },
      featureTitle
    );

    // Add retry context if not first iteration
    if (state.iteration > 1 && state.lastError) {
      prompt += `\n\n## Previous Attempt Failed\n\nIteration: ${state.iteration - 1}\nError: ${state.lastError}\n\nPlease analyze the error and try a different approach.`;
    }

    const options: SpawnOptions = {
      model: this.config.model || 'sonnet',
      dangerouslySkipPermissions: this.config.dangerouslySkipPermissions,
      maxTurns: 50,
      timeoutMs: 30 * 60 * 1000, // 30 minutes
    };

    try {
      return await this.claude.run(prompt, options);
    } catch (error) {
      return {
        status: 'error',
        commits: [],
        rawOutput: '',
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  /**
   * Check if error is fatal (should not retry)
   */
  private isFatalError(output: ClaudeOutput): boolean {
    const errorText = (output.error || output.blockerReason || '').toLowerCase();
    return this.config.fatalErrors.some(fatal =>
      errorText.includes(fatal.toLowerCase())
    );
  }

  /**
   * Detect if stuck in a loop (same error repeated)
   */
  private isStuck(state: IterationState): boolean {
    if (state.history.length < 3) return false;

    // Get last 3 errors
    const lastThree = state.history.slice(-3);
    const errors = lastThree.map(a => a.error).filter(Boolean);

    if (errors.length < 3) return false;

    // Check if all errors are the same
    return errors.every(e => e === errors[0]);
  }

  /**
   * Get iteration state for a story
   */
  getState(storyId: string): IterationState | undefined {
    return this.states.get(storyId);
  }

  /**
   * Clear iteration state
   */
  clearState(storyId: string): void {
    this.states.delete(storyId);
  }

  /**
   * Delay helper
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Analyze stuck patterns across multiple stories
   */
  analyzeStuckPatterns(results: IterationResult[]): StuckAnalysis {
    const stuckResults = results.filter(r => !r.success && r.stuckReason);

    const patterns: Record<string, number> = {};
    for (const result of stuckResults) {
      // Extract pattern from stuck reason
      const pattern = this.extractPattern(result.stuckReason || '');
      patterns[pattern] = (patterns[pattern] || 0) + 1;
    }

    return {
      totalStuck: stuckResults.length,
      patterns: Object.entries(patterns)
        .map(([pattern, count]) => ({ pattern, count }))
        .sort((a, b) => b.count - a.count),
      recommendations: this.generateRecommendations(patterns),
    };
  }

  /**
   * Extract pattern from error
   */
  private extractPattern(reason: string): string {
    // Common patterns
    if (reason.includes('test') || reason.includes('Test')) return 'test_failure';
    if (reason.includes('import') || reason.includes('module')) return 'import_error';
    if (reason.includes('type') || reason.includes('Type')) return 'type_error';
    if (reason.includes('permission') || reason.includes('Permission')) return 'permission_error';
    if (reason.includes('timeout') || reason.includes('Timeout')) return 'timeout';
    if (reason.includes('needs input') || reason.includes('Needs input')) return 'needs_input';
    return 'other';
  }

  /**
   * Generate recommendations based on stuck patterns
   */
  private generateRecommendations(patterns: Record<string, number>): string[] {
    const recommendations: string[] = [];

    if (patterns['test_failure'] > 0) {
      recommendations.push('Consider reviewing test setup and mocking strategies');
    }
    if (patterns['import_error'] > 0) {
      recommendations.push('Check module resolution and dependencies');
    }
    if (patterns['type_error'] > 0) {
      recommendations.push('Review TypeScript configuration and type definitions');
    }
    if (patterns['timeout'] > 0) {
      recommendations.push('Increase timeout limits or simplify story scope');
    }
    if (patterns['needs_input'] > 0) {
      recommendations.push('Provide more context in story scope or add default values');
    }

    return recommendations;
  }
}

export interface StuckAnalysis {
  totalStuck: number;
  patterns: { pattern: string; count: number }[];
  recommendations: string[];
}
