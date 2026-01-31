// Progress reporting and feedback for sessions

import chalk from 'chalk';

export interface ProgressEvent {
  type: 'start' | 'story_start' | 'story_complete' | 'story_blocked' | 'iteration' | 'error' | 'complete' | 'checkpoint';
  timestamp: Date;
  message: string;
  details?: Record<string, unknown>;
}

export interface ProgressStats {
  totalStories: number;
  completedStories: number;
  blockedStories: number;
  totalIterations: number;
  elapsedMinutes: number;
  estimatedRemainingMinutes?: number;
}

export type ProgressCallback = (event: ProgressEvent, stats: ProgressStats) => void;

export class ProgressReporter {
  private events: ProgressEvent[] = [];
  private startTime: Date;
  private stats: ProgressStats;
  private callbacks: ProgressCallback[] = [];
  private logToConsole: boolean;

  constructor(totalStories: number, logToConsole: boolean = true) {
    this.startTime = new Date();
    this.logToConsole = logToConsole;
    this.stats = {
      totalStories,
      completedStories: 0,
      blockedStories: 0,
      totalIterations: 0,
      elapsedMinutes: 0,
    };
  }

  /**
   * Register a callback for progress events
   */
  onProgress(callback: ProgressCallback): void {
    this.callbacks.push(callback);
  }

  /**
   * Emit a progress event
   */
  private emit(event: ProgressEvent): void {
    this.events.push(event);
    this.stats.elapsedMinutes = (Date.now() - this.startTime.getTime()) / 1000 / 60;

    // Calculate estimated remaining time based on average time per story
    if (this.stats.completedStories > 0) {
      const avgTimePerStory = this.stats.elapsedMinutes / this.stats.completedStories;
      const remainingStories = this.stats.totalStories - this.stats.completedStories - this.stats.blockedStories;
      this.stats.estimatedRemainingMinutes = avgTimePerStory * remainingStories;
    }

    // Notify callbacks
    for (const cb of this.callbacks) {
      try {
        cb(event, { ...this.stats });
      } catch {
        // Ignore callback errors
      }
    }

    // Console output
    if (this.logToConsole) {
      this.logEvent(event);
    }
  }

  /**
   * Log event to console
   */
  private logEvent(event: ProgressEvent): void {
    const bar = this.renderProgressBar();

    switch (event.type) {
      case 'start':
        console.log(chalk.blue(`\n🚀 ${event.message}`));
        console.log(chalk.dim(bar));
        break;
      case 'story_start':
        console.log(chalk.cyan(`\n📋 ${event.message}`));
        break;
      case 'story_complete':
        console.log(chalk.green(`✓ ${event.message}`));
        console.log(chalk.dim(bar));
        break;
      case 'story_blocked':
        console.log(chalk.yellow(`🚫 ${event.message}`));
        break;
      case 'iteration':
        console.log(chalk.dim(`   ↻ ${event.message}`));
        break;
      case 'error':
        console.log(chalk.red(`✗ ${event.message}`));
        break;
      case 'complete':
        console.log(chalk.green(`\n✅ ${event.message}`));
        this.printSummary();
        break;
      case 'checkpoint':
        console.log(chalk.dim(`   💾 ${event.message}`));
        break;
    }
  }

  /**
   * Render a progress bar
   */
  private renderProgressBar(): string {
    const { completedStories, blockedStories, totalStories } = this.stats;
    const done = completedStories;
    const blocked = blockedStories;
    const remaining = totalStories - done - blocked;

    const width = 30;
    const doneWidth = Math.round((done / totalStories) * width);
    const blockedWidth = Math.round((blocked / totalStories) * width);
    const remainingWidth = width - doneWidth - blockedWidth;

    const bar = chalk.green('█'.repeat(doneWidth)) +
                chalk.yellow('█'.repeat(blockedWidth)) +
                chalk.gray('░'.repeat(remainingWidth));

    const percent = Math.round((done / totalStories) * 100);
    const eta = this.stats.estimatedRemainingMinutes
      ? ` ETA: ${this.stats.estimatedRemainingMinutes.toFixed(0)}m`
      : '';

    return `[${bar}] ${percent}% (${done}/${totalStories})${eta}`;
  }

  /**
   * Print final summary
   */
  private printSummary(): void {
    const { completedStories, blockedStories, totalStories, totalIterations, elapsedMinutes } = this.stats;

    console.log(chalk.blue('\n📊 Session Summary'));
    console.log(`   Duration: ${elapsedMinutes.toFixed(1)} minutes`);
    console.log(`   Stories: ${completedStories}/${totalStories} completed, ${blockedStories} blocked`);
    console.log(`   Iterations: ${totalIterations}`);

    if (completedStories > 0) {
      console.log(`   Avg time/story: ${(elapsedMinutes / completedStories).toFixed(1)} minutes`);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Event Methods
  // ─────────────────────────────────────────────────────────────

  sessionStart(featureTitle: string): void {
    this.emit({
      type: 'start',
      timestamp: new Date(),
      message: `Starting session: "${featureTitle}"`,
      details: { feature: featureTitle },
    });
  }

  storyStart(storyId: string, storyTitle: string): void {
    this.emit({
      type: 'story_start',
      timestamp: new Date(),
      message: `Story ${storyId}: "${storyTitle}"`,
      details: { storyId, storyTitle },
    });
  }

  storyComplete(storyId: string, commits: number, iterations: number): void {
    this.stats.completedStories++;
    this.stats.totalIterations += iterations;
    this.emit({
      type: 'story_complete',
      timestamp: new Date(),
      message: `Story ${storyId} complete (${commits} commits, ${iterations} iteration${iterations > 1 ? 's' : ''})`,
      details: { storyId, commits, iterations },
    });
  }

  storyBlocked(storyId: string, reason: string): void {
    this.stats.blockedStories++;
    this.emit({
      type: 'story_blocked',
      timestamp: new Date(),
      message: `Story ${storyId} blocked: ${reason}`,
      details: { storyId, reason },
    });
  }

  iteration(storyId: string, iterationNumber: number, reason: string): void {
    this.emit({
      type: 'iteration',
      timestamp: new Date(),
      message: `Iteration ${iterationNumber}: ${reason}`,
      details: { storyId, iterationNumber, reason },
    });
  }

  error(message: string, error?: Error): void {
    this.emit({
      type: 'error',
      timestamp: new Date(),
      message,
      details: { error: error?.message, stack: error?.stack },
    });
  }

  sessionComplete(success: boolean): void {
    this.emit({
      type: 'complete',
      timestamp: new Date(),
      message: success ? 'Session completed successfully!' : 'Session ended with issues',
      details: { success },
    });
  }

  checkpoint(featureId: string): void {
    this.emit({
      type: 'checkpoint',
      timestamp: new Date(),
      message: `Checkpoint saved for ${featureId}`,
      details: { featureId },
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Utility Methods
  // ─────────────────────────────────────────────────────────────

  getStats(): ProgressStats {
    this.stats.elapsedMinutes = (Date.now() - this.startTime.getTime()) / 1000 / 60;
    return { ...this.stats };
  }

  getEvents(): ProgressEvent[] {
    return [...this.events];
  }

  /**
   * Format events as a log string
   */
  formatLog(): string {
    return this.events.map(e => {
      const time = e.timestamp.toISOString().split('T')[1].split('.')[0];
      return `[${time}] ${e.type}: ${e.message}`;
    }).join('\n');
  }
}

/**
 * Simple spinner for async operations
 */
export function createSpinner(text: string): {
  start: () => void;
  stop: () => void;
  update: (text: string) => void;
  succeed: (text?: string) => void;
  fail: (text?: string) => void;
} {
  let interval: NodeJS.Timeout | null = null;
  const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  let frameIndex = 0;
  let currentText = text;

  return {
    start() {
      if (interval) return;
      interval = setInterval(() => {
        process.stdout.write(`\r${chalk.cyan(frames[frameIndex])} ${currentText}`);
        frameIndex = (frameIndex + 1) % frames.length;
      }, 80);
    },
    stop() {
      if (interval) {
        clearInterval(interval);
        interval = null;
        process.stdout.write('\r' + ' '.repeat(currentText.length + 4) + '\r');
      }
    },
    update(newText: string) {
      currentText = newText;
    },
    succeed(newText?: string) {
      this.stop();
      console.log(`${chalk.green('✓')} ${newText || currentText}`);
    },
    fail(newText?: string) {
      this.stop();
      console.log(`${chalk.red('✗')} ${newText || currentText}`);
    },
  };
}
