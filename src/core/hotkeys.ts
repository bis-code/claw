// Hotkey handling for mid-execution control

import chalk from 'chalk';
import readline from 'readline';

export type HotkeyAction = 'pause' | 'skip' | 'abort' | 'ask' | 'pivot' | 'status' | 'help';

export interface HotkeyHandler {
  key: string;
  action: HotkeyAction;
  description: string;
  handler: () => void | Promise<void>;
}

export interface HotkeyManagerOptions {
  onPause?: () => void | Promise<void>;
  onSkip?: () => void | Promise<void>;
  onAbort?: () => void | Promise<void>;
  onAsk?: () => void | Promise<void>;
  onPivot?: () => void | Promise<void>;
  onStatus?: () => void | Promise<void>;
}

export class HotkeyManager {
  private rl: readline.Interface | null = null;
  private handlers: Map<string, HotkeyHandler> = new Map();
  private isActive: boolean = false;
  private options: HotkeyManagerOptions;

  constructor(options: HotkeyManagerOptions = {}) {
    this.options = options;
    this.setupDefaultHandlers();
  }

  /**
   * Setup default hotkey handlers
   */
  private setupDefaultHandlers(): void {
    this.registerHandler({
      key: 'p',
      action: 'pause',
      description: 'Pause execution',
      handler: () => this.options.onPause?.(),
    });

    this.registerHandler({
      key: 's',
      action: 'skip',
      description: 'Skip current story',
      handler: () => this.options.onSkip?.(),
    });

    this.registerHandler({
      key: 'q',
      action: 'abort',
      description: 'Abort session',
      handler: () => this.options.onAbort?.(),
    });

    this.registerHandler({
      key: '?',
      action: 'ask',
      description: 'Ask Claude a question',
      handler: () => this.options.onAsk?.(),
    });

    this.registerHandler({
      key: 'v',
      action: 'pivot',
      description: 'Open pivot menu',
      handler: () => this.options.onPivot?.(),
    });

    this.registerHandler({
      key: 'i',
      action: 'status',
      description: 'Show status',
      handler: () => this.options.onStatus?.(),
    });

    this.registerHandler({
      key: 'h',
      action: 'help',
      description: 'Show help',
      handler: () => this.showHelp(),
    });
  }

  /**
   * Register a hotkey handler
   */
  registerHandler(handler: HotkeyHandler): void {
    this.handlers.set(handler.key.toLowerCase(), handler);
  }

  /**
   * Start listening for hotkeys
   */
  start(): void {
    if (this.isActive) return;

    // Only setup if stdin is a TTY
    if (!process.stdin.isTTY) {
      return;
    }

    this.isActive = true;

    // Set raw mode to capture individual keypresses
    if (process.stdin.setRawMode) {
      process.stdin.setRawMode(true);
    }
    process.stdin.resume();

    // Listen for keypress
    process.stdin.on('data', this.handleKeypress.bind(this));

    // Show hint
    console.log(chalk.dim('\n[Press h for help, p to pause, q to abort]\n'));
  }

  /**
   * Stop listening for hotkeys
   */
  stop(): void {
    if (!this.isActive) return;

    this.isActive = false;

    if (process.stdin.setRawMode) {
      process.stdin.setRawMode(false);
    }
    process.stdin.pause();
    process.stdin.removeAllListeners('data');
  }

  /**
   * Handle a keypress
   */
  private async handleKeypress(data: Buffer): Promise<void> {
    const key = data.toString().toLowerCase();

    // Handle Ctrl+C
    if (data[0] === 3) {
      console.log(chalk.yellow('\n\n⚠️  Ctrl+C detected - aborting...'));
      await this.options.onAbort?.();
      return;
    }

    const handler = this.handlers.get(key);
    if (handler) {
      try {
        await handler.handler();
      } catch (error) {
        console.log(chalk.red(`\nError handling hotkey: ${error}`));
      }
    }
  }

  /**
   * Show help message
   */
  private showHelp(): void {
    console.log(chalk.blue('\n📌 Available Hotkeys:\n'));

    const sortedHandlers = Array.from(this.handlers.values())
      .sort((a, b) => a.key.localeCompare(b.key));

    for (const handler of sortedHandlers) {
      console.log(`  ${chalk.bold(handler.key)}  ${handler.description}`);
    }

    console.log('');
  }

  /**
   * Check if hotkeys are active
   */
  isListening(): boolean {
    return this.isActive;
  }

  /**
   * Temporarily disable hotkeys (e.g., during prompts)
   */
  suspend(): void {
    if (this.isActive && process.stdin.setRawMode) {
      process.stdin.setRawMode(false);
    }
  }

  /**
   * Resume hotkeys after suspension
   */
  resume(): void {
    if (this.isActive && process.stdin.setRawMode) {
      process.stdin.setRawMode(true);
    }
  }
}

/**
 * Create a simple spinner with hotkey support
 */
export function createHotkeyAwareSpinner(text: string): {
  start: () => void;
  stop: () => void;
  succeed: (text?: string) => void;
  fail: (text?: string) => void;
  text: string;
} {
  let interval: NodeJS.Timeout | null = null;
  const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  let frameIndex = 0;
  let currentText = text;

  return {
    get text() {
      return currentText;
    },
    set text(value: string) {
      currentText = value;
    },
    start() {
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
