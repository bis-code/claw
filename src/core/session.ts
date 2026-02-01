// Session runner - autonomous execution loop

import chalk from 'chalk';
import ora from 'ora';
import inquirer from 'inquirer';
import { ClaudeClient, ClaudeOutput, SpawnOptions } from '../integrations/claude.js';
import { ObsidianClient } from '../integrations/obsidian.js';
import { DependencyManager } from './dependencies.js';
import { Feature, Story, FeatureManager } from './feature.js';
import { IterationEngine, IterationResult } from './iteration.js';
import { GitHubClient, GitHubPR } from '../integrations/github.js';
import { CheckpointManager } from './checkpoint.js';
import { HotkeyManager } from './hotkeys.js';

export interface SessionConfig {
  /** Maximum hours to run (undefined = no limit) */
  maxHours?: number;
  /** Maximum stories to complete */
  maxStories?: number;
  /** Stop at first blocker */
  stopOnBlocker?: boolean;
  /** Pause between stories for review */
  pauseBetweenStories?: boolean;
  /** Claude model to use */
  model?: 'sonnet' | 'opus' | 'haiku';
  /** Skip permission prompts */
  dangerouslySkipPermissions?: boolean;
  /** Maximum iterations per story for retry */
  maxIterations?: number;
  /** Enable iteration-until-green mode */
  iterateUntilGreen?: boolean;
  /** Create PR after each story completion */
  createPRPerStory?: boolean;
  /** Create PR after all stories complete */
  createPROnComplete?: boolean;
  /** Run Claude interactively (user sees output and can interact) */
  interactive?: boolean;
}

export interface SessionState {
  startTime: Date;
  feature: Feature;
  storiesCompleted: number;
  storiesBlocked: number;
  totalIterations: number;
  currentStory: Story | null;
  status: 'running' | 'paused' | 'completed' | 'blocked' | 'timeout' | 'error';
  blockerReason?: string;
  pendingQuestion?: string;
}

export interface SessionResult {
  success: boolean;
  storiesCompleted: number;
  storiesBlocked: number;
  totalDuration: number;
  commits: string[];
  prs: number[];
  error?: string;
  finalState: SessionState;
}

export class SessionRunner {
  private claude: ClaudeClient;
  private obsidian: ObsidianClient;
  private featureManager: FeatureManager;
  private depManager: DependencyManager;
  private github: GitHubClient;
  private checkpointManager: CheckpointManager;
  private hotkeyManager: HotkeyManager;
  private iterationEngine: IterationEngine | null = null;
  private workingDir: string;
  private state: SessionState | null = null;
  private currentConfig: SessionConfig | null = null;
  private isPivoting: boolean = false;

  constructor(
    workingDir: string,
    vaultPath: string,
    projectPath: string
  ) {
    this.workingDir = workingDir;
    this.claude = new ClaudeClient(workingDir);
    this.obsidian = new ObsidianClient(vaultPath);
    this.featureManager = new FeatureManager(vaultPath, projectPath);
    this.depManager = new DependencyManager();
    this.github = new GitHubClient(workingDir);
    this.checkpointManager = new CheckpointManager(vaultPath, projectPath);

    // Initialize hotkey manager with callbacks
    this.hotkeyManager = new HotkeyManager({
      onPause: () => this.handleHotkeyPause(),
      onSkip: () => this.handleHotkeySkip(),
      onAbort: () => this.handleHotkeyAbort(),
      onAsk: () => this.handleHotkeyAsk(),
      onPivot: () => this.handleHotkeyPivot(),
      onStatus: () => this.handleHotkeyStatus(),
    });
  }

  /**
   * Run a feature session
   */
  async run(feature: Feature, config: SessionConfig): Promise<SessionResult> {
    const startTime = new Date();
    const commits: string[] = [];
    const prs: number[] = [];

    // Save config for checkpointing
    this.currentConfig = config;

    // Initialize state
    this.state = {
      startTime,
      feature,
      storiesCompleted: 0,
      storiesBlocked: 0,
      totalIterations: 0,
      currentStory: null,
      status: 'running',
    };

    // Initialize iteration engine if enabled
    if (config.iterateUntilGreen) {
      this.iterationEngine = new IterationEngine(this.workingDir, {
        maxIterations: config.maxIterations || 5,
        model: config.model,
        dangerouslySkipPermissions: config.dangerouslySkipPermissions,
      });
    }

    // Build dependency graph
    this.depManager.buildFromStories(feature.stories);

    console.log(chalk.blue(`\n🚀 Starting session: "${feature.title}"`));
    console.log(chalk.dim(`   Budget: ${config.maxHours ? `${config.maxHours} hours` : 'unlimited (until blocked)'}`));
    console.log(chalk.dim(`   Stories: ${feature.stories.length}`));

    // If maxHours is undefined, no time limit (run until blocked or complete)
    const deadline = config.maxHours
      ? new Date(startTime.getTime() + config.maxHours * 60 * 60 * 1000)
      : null;

    // Start listening for hotkeys
    this.hotkeyManager.start();

    try {
      // Main execution loop
      while (this.state.status === 'running') {
        // Check time budget (only if a deadline is set)
        if (deadline && new Date() >= deadline) {
          console.log(chalk.yellow('\n⏰ Time budget exhausted'));
          this.state.status = 'timeout';
          break;
        }

        // Check story limit
        if (config.maxStories && this.state.storiesCompleted >= config.maxStories) {
          console.log(chalk.green(`\n✓ Completed ${config.maxStories} stories (limit reached)`));
          this.state.status = 'completed';
          break;
        }

        // Get next story
        const nextNode = this.depManager.getNextStory();
        if (!nextNode) {
          const progress = this.depManager.getProgress();
          if (progress.complete === progress.total) {
            console.log(chalk.green('\n✓ All stories completed!'));
            this.state.status = 'completed';
          } else if (progress.blocked > 0 || progress.pending > 0) {
            console.log(chalk.yellow('\n⚠️  No ready stories - all remaining are blocked'));
            this.state.status = 'blocked';
          }
          break;
        }

        // Find the actual story object
        const story = feature.stories.find(s => s.id === nextNode.id);
        if (!story) {
          console.log(chalk.red(`\n✗ Story not found: ${nextNode.id}`));
          continue;
        }

        this.state.currentStory = story;
        this.depManager.markInProgress(story.id);

        // Pause for review if configured
        if (config.pauseBetweenStories && this.state.storiesCompleted > 0) {
          const { proceed } = await inquirer.prompt([{
            type: 'confirm',
            name: 'proceed',
            message: `Continue with story "${story.title}"?`,
            default: true,
          }]);

          if (!proceed) {
            this.state.status = 'paused';
            break;
          }
        }

        // Execute story
        console.log(chalk.blue(`\n📋 Story ${story.id}: "${story.title}"`));
        await this.featureManager.updateStory(feature.id, story.id, { status: 'in_progress' });

        // Use iteration engine if enabled, otherwise single execution
        let result: ClaudeOutput;
        let iterations = 1;

        if (this.iterationEngine) {
          const iterResult = await this.iterationEngine.executeUntilGreen(story, feature.title);
          iterations = iterResult.iterations;
          result = iterResult.finalOutput;
          this.state.totalIterations += iterations;

          if (!iterResult.success && iterResult.stuckReason) {
            console.log(chalk.yellow(`   ⚠️  ${iterResult.stuckReason}`));
          }
        } else {
          result = await this.executeStory(story, feature.title, config);
        }

        // Handle result
        if (result.status === 'complete') {
          commits.push(...result.commits);
          if (result.pr) prs.push(result.pr);

          this.depManager.markComplete(story.id);
          await this.featureManager.updateStory(feature.id, story.id, {
            status: 'complete',
            iterations,
          });
          this.state.storiesCompleted++;

          console.log(chalk.green(`   ✓ Story complete (${result.commits.length} commits, ${iterations} iteration${iterations > 1 ? 's' : ''})`));

          // Create PR if configured
          if (config.createPRPerStory && result.commits.length > 0) {
            try {
              const pr = await this.createStoryPR(story, feature, result.commits);
              if (pr) {
                prs.push(pr.number);
                await this.featureManager.updateStory(feature.id, story.id, { pr: pr.number });
                console.log(chalk.green(`   📝 PR created: #${pr.number}`));
              }
            } catch (error) {
              console.log(chalk.yellow(`   ⚠️  Failed to create PR: ${error instanceof Error ? error.message : error}`));
            }
          }
        } else if (result.status === 'blocked') {
          this.depManager.markBlocked(story.id);
          await this.featureManager.updateStory(feature.id, story.id, {
            status: 'blocked',
            iterations,
          });
          this.state.storiesBlocked++;
          this.state.blockerReason = result.blockerReason;

          console.log(chalk.yellow(`   🚫 Blocked: ${result.blockerReason}`));

          if (config.stopOnBlocker) {
            this.state.status = 'blocked';
            break;
          }
        } else if (result.status === 'needs_input') {
          this.state.pendingQuestion = result.question;
          this.state.status = 'paused';

          console.log(chalk.cyan(`   ❓ Input needed: ${result.question}`));

          // Prompt for answer
          const { answer } = await inquirer.prompt([{
            type: 'input',
            name: 'answer',
            message: result.question || 'Please provide input:',
          }]);

          // Continue with the answer (in a real implementation, we'd pass this back to Claude)
          console.log(chalk.dim(`   → Answer recorded: ${answer}`));
          this.state.status = 'running';
          this.state.pendingQuestion = undefined;
        } else if (result.status === 'error' || result.status === 'timeout') {
          console.log(chalk.red(`   ✗ ${result.status}: ${result.error}`));
          await this.featureManager.updateStory(feature.id, story.id, {
            status: 'blocked',
            iterations,
          });
          this.state.storiesBlocked++;

          if (config.stopOnBlocker) {
            this.state.status = 'error';
            this.state.blockerReason = result.error;
            break;
          }
        }

        // Update Obsidian with session log
        await this.logProgress(story, result, iterations);

        // Save checkpoint after each story
        await this.saveCheckpoint(feature);
      }
    } catch (error) {
      this.state.status = 'error';
      this.state.blockerReason = error instanceof Error ? error.message : String(error);
      console.log(chalk.red(`\n✗ Session error: ${this.state.blockerReason}`));

      // Save checkpoint on error
      await this.saveCheckpoint(feature);

      // Stop hotkey listening on error
      this.hotkeyManager.stop();
    }

    const totalDuration = (new Date().getTime() - startTime.getTime()) / 1000 / 60; // minutes

    // Create feature PR if configured and session completed successfully
    if (config.createPROnComplete && this.state.status === 'completed' && commits.length > 0) {
      try {
        console.log(chalk.blue('\n📝 Creating pull request...'));
        const pr = await this.createFeaturePR(feature, commits);
        if (pr) {
          prs.push(pr.number);
          console.log(chalk.green(`   ✓ PR created: #${pr.number} (${pr.url})`));
        }
      } catch (error) {
        console.log(chalk.yellow(`   ⚠️  Failed to create PR: ${error instanceof Error ? error.message : error}`));
      }
    }

    // Stop listening for hotkeys
    this.hotkeyManager.stop();

    // Summary
    console.log(chalk.blue('\n📊 Session Summary'));
    console.log(`   Duration: ${totalDuration.toFixed(1)} minutes`);
    console.log(`   Completed: ${this.state.storiesCompleted} stories`);
    console.log(`   Blocked: ${this.state.storiesBlocked} stories`);
    console.log(`   Total iterations: ${this.state.totalIterations}`);
    console.log(`   Commits: ${commits.length}`);
    console.log(`   PRs: ${prs.length}`);

    return {
      success: this.state.status === 'completed',
      storiesCompleted: this.state.storiesCompleted,
      storiesBlocked: this.state.storiesBlocked,
      totalDuration,
      commits,
      prs,
      error: this.state.blockerReason,
      finalState: this.state,
    };
  }

  /**
   * Execute a single story
   */
  private async executeStory(
    story: Story,
    featureTitle: string,
    config: SessionConfig
  ): Promise<ClaudeOutput> {
    // Build prompt
    const prompt = this.claude.generateStoryPrompt(
      {
        title: story.title,
        scope: story.scope,
        repos: story.repos,
      },
      featureTitle
    );

    // Interactive mode: run Claude directly in terminal
    if (config.interactive) {
      // Display the story context so user knows what to work on
      console.log(chalk.blue('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
      console.log(chalk.bold('📋 Story Context'));
      console.log(chalk.blue('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
      console.log(chalk.yellow(`\nTitle: ${story.title}`));
      console.log(chalk.dim(`Feature: ${featureTitle}`));
      console.log(chalk.dim('\nScope:'));
      story.scope.forEach(s => console.log(chalk.dim(`  - ${s}`)));
      console.log(chalk.blue('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'));

      console.log(chalk.green('Starting Claude... You can:'));
      console.log(chalk.dim('  - Describe what you want Claude to do'));
      console.log(chalk.dim('  - Answer Claude\'s questions'));
      console.log(chalk.dim('  - Press Escape twice to exit when done'));
      console.log(chalk.dim('\nThe story context is also saved to .claw-context.md\n'));

      try {
        const exitCode = await this.claude.runInteractive(prompt, {
          model: config.model || 'sonnet',
          dangerouslySkipPermissions: config.dangerouslySkipPermissions,
          maxTurns: 50,
        });

        console.log(chalk.dim('\n--- Session ended ---'));

        // Ask if story is complete
        const { status } = await inquirer.prompt([{
          type: 'list',
          name: 'status',
          message: 'Is this story complete?',
          choices: [
            { name: 'Yes, mark as complete', value: 'complete' },
            { name: 'No, I\'m blocked', value: 'blocked' },
            { name: 'Still in progress, continue later', value: 'in_progress' },
          ],
        }]);

        return {
          status: status as 'complete' | 'blocked' | 'error',
          commits: [],
          rawOutput: '',
          exitCode,
          blockerReason: status === 'blocked' ? 'User marked as blocked' : undefined,
        };
      } catch (error) {
        return {
          status: 'error',
          commits: [],
          rawOutput: '',
          error: error instanceof Error ? error.message : String(error),
        };
      }
    }

    // Non-interactive mode: capture output with spinner
    const spinner = ora(`Executing: ${story.title}`).start();

    const options: SpawnOptions = {
      model: config.model || 'sonnet',
      dangerouslySkipPermissions: config.dangerouslySkipPermissions,
      maxTurns: 50,
      timeoutMs: 30 * 60 * 1000, // 30 minutes per story
    };

    try {
      const output = await this.claude.run(prompt, options);
      spinner.stop();
      return output;
    } catch (error) {
      spinner.fail('Execution failed');
      return {
        status: 'error',
        commits: [],
        rawOutput: '',
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  /**
   * Create a PR for a completed story
   */
  private async createStoryPR(story: Story, feature: Feature, commits: string[]): Promise<GitHubPR | null> {
    // Check if there's already a PR for this branch
    const existingPR = await this.github.getExistingPR();
    if (existingPR) {
      console.log(chalk.dim(`   PR already exists: #${existingPR.number}`));
      return existingPR;
    }

    // Push the branch first
    const pushed = await this.github.pushBranch();
    if (!pushed) {
      console.log(chalk.yellow(`   ⚠️  Failed to push branch`));
      return null;
    }

    // Generate PR body
    const commitList = commits.map(c => `- ${c}`).join('\n');
    const body = `## Summary

Implements story: **${story.title}**

Part of feature: **${feature.title}**

## Scope
${story.scope.map(s => `- ${s}`).join('\n')}

## Commits
${commitList}

---
🤖 Generated by claw`;

    // Create PR
    const defaultBranch = await this.github.getDefaultBranch();
    return this.github.createPR({
      title: `feat: ${story.title}`,
      body,
      base: defaultBranch,
    });
  }

  /**
   * Create a PR for the entire feature session
   */
  private async createFeaturePR(feature: Feature, commits: string[]): Promise<GitHubPR | null> {
    // Check if there's already a PR for this branch
    const existingPR = await this.github.getExistingPR();
    if (existingPR) {
      return existingPR;
    }

    // Push the branch first
    const pushed = await this.github.pushBranch();
    if (!pushed) {
      return null;
    }

    // Generate PR body
    const completedStories = feature.stories.filter(s => s.status === 'complete');
    const storyList = completedStories.map(s => `- [x] ${s.title}`).join('\n');
    const pendingStories = feature.stories.filter(s => s.status !== 'complete');
    const pendingList = pendingStories.map(s => `- [ ] ${s.title}`).join('\n');

    const body = `## Summary

Feature: **${feature.title}**

${feature.description}

## Stories Completed
${storyList}

${pendingList ? `## Remaining Stories\n${pendingList}` : ''}

## Commits
${commits.slice(0, 20).map(c => `- ${c}`).join('\n')}
${commits.length > 20 ? `\n... and ${commits.length - 20} more` : ''}

---
🤖 Generated by claw`;

    const defaultBranch = await this.github.getDefaultBranch();
    return this.github.createPR({
      title: `feat: ${feature.title}`,
      body,
      base: defaultBranch,
    });
  }

  /**
   * Log progress to Obsidian
   */
  private async logProgress(story: Story, result: ClaudeOutput, iterations: number = 1): Promise<void> {
    if (!this.state) return;

    const date = new Date().toISOString().split('T')[0];
    const action = result.status === 'complete' ? 'Completed' :
                   result.status === 'blocked' ? 'Blocked' :
                   result.status === 'needs_input' ? 'Paused' : 'Error';
    const iterText = iterations > 1 ? ` (${iterations} iterations)` : '';
    const details = result.status === 'complete'
      ? `${result.commits.length} commits${iterText}`
      : (result.blockerReason || result.question || result.error || '') + iterText;

    await this.obsidian.appendSessionLog(
      `Projects/${this.state.feature.id}/_overview`,
      { date, action: `Story ${story.id}: ${action}`, details }
    );
  }

  /**
   * Save checkpoint to Obsidian
   */
  private async saveCheckpoint(feature: Feature): Promise<void> {
    if (!this.state || !this.currentConfig) return;

    try {
      // Re-fetch feature to get latest story states
      const updatedFeature = await this.featureManager.get(feature.id) || feature;
      await this.checkpointManager.saveCheckpoint(updatedFeature, this.state, this.currentConfig);
    } catch (error) {
      console.log(chalk.dim(`   (Failed to save checkpoint: ${error instanceof Error ? error.message : error})`));
    }
  }

  /**
   * Get current state
   */
  getState(): SessionState | null {
    return this.state;
  }

  /**
   * Pause the session
   */
  pause(): void {
    if (this.state) {
      this.state.status = 'paused';
    }
  }

  /**
   * Check if a feature has a resumable checkpoint
   */
  async hasCheckpoint(featureId: string): Promise<boolean> {
    return this.checkpointManager.hasCheckpoint(featureId);
  }

  /**
   * Get checkpoint data for a feature
   */
  async getCheckpoint(featureId: string) {
    return this.checkpointManager.loadCheckpoint(featureId);
  }

  /**
   * Resume a paused session from checkpoint
   */
  async resume(feature: Feature, config?: Partial<SessionConfig>): Promise<SessionResult> {
    // Load checkpoint
    const checkpoint = await this.checkpointManager.loadCheckpoint(feature.id);

    if (!checkpoint) {
      console.log(chalk.yellow('No checkpoint found, starting fresh.'));
      return this.run(feature, config as SessionConfig);
    }

    console.log(chalk.blue(`\n📂 Resuming from checkpoint`));
    console.log(chalk.dim(`   Previous status: ${checkpoint.sessionState.status}`));
    console.log(chalk.dim(`   Stories completed: ${checkpoint.sessionState.storiesCompleted}`));
    console.log(chalk.dim(`   Remaining time: ${this.checkpointManager.getRemainingTime(checkpoint).toFixed(1)}h`));

    // Merge checkpoint config with provided overrides
    const resumeConfig: SessionConfig = {
      ...checkpoint.config as SessionConfig,
      ...config,
      // Preserve unlimited time if original session had no limit, otherwise use remaining time
      maxHours: config?.maxHours !== undefined
        ? config.maxHours
        : (checkpoint.config.maxHours !== undefined
            ? this.checkpointManager.getRemainingTime(checkpoint)
            : undefined),
    };

    // Delete old checkpoint before starting fresh run
    // (new checkpoints will be created during the run)
    await this.checkpointManager.deleteCheckpoint(feature.id);

    return this.run(feature, resumeConfig);
  }

  /**
   * Clean up checkpoint after successful completion
   */
  async cleanupCheckpoint(featureId: string): Promise<void> {
    await this.checkpointManager.deleteCheckpoint(featureId);
  }

  /**
   * Interrupt the current session
   */
  async interrupt(action: 'pause' | 'skip' | 'abort'): Promise<void> {
    if (!this.state) return;

    switch (action) {
      case 'pause':
        this.state.status = 'paused';
        console.log(chalk.yellow('\n⏸️  Session paused'));
        break;
      case 'skip':
        if (this.state.currentStory) {
          this.depManager.markBlocked(this.state.currentStory.id);
          console.log(chalk.yellow(`\n⏭️  Skipped story: ${this.state.currentStory.title}`));
        }
        break;
      case 'abort':
        this.state.status = 'error';
        this.state.blockerReason = 'User aborted';
        console.log(chalk.red('\n🛑 Session aborted'));
        break;
    }
  }

  /**
   * Ask Claude a question mid-session
   */
  async askClaude(question: string): Promise<string> {
    if (!this.state?.currentStory) {
      return 'No active session';
    }

    console.log(chalk.cyan(`\n❓ Asking Claude: ${question}`));

    const output = await this.claude.run(
      `Context: Working on story "${this.state.currentStory.title}"\n\nQuestion: ${question}\n\nProvide a brief, helpful response.`,
      { model: 'haiku', maxTurns: 3, dangerouslySkipPermissions: true }
    );

    return output.rawOutput;
  }

  // ─────────────────────────────────────────────────────────────
  // Hotkey Handlers
  // ─────────────────────────────────────────────────────────────

  /**
   * Handle pause hotkey (p)
   */
  private async handleHotkeyPause(): Promise<void> {
    await this.interrupt('pause');
    if (this.state) {
      await this.saveCheckpoint(this.state.feature);
    }
  }

  /**
   * Handle skip hotkey (s)
   */
  private async handleHotkeySkip(): Promise<void> {
    await this.interrupt('skip');
  }

  /**
   * Handle abort hotkey (q) or Ctrl+C
   */
  private async handleHotkeyAbort(): Promise<void> {
    if (this.state) {
      await this.saveCheckpoint(this.state.feature);
    }
    await this.interrupt('abort');
  }

  /**
   * Handle ask hotkey (?)
   */
  private async handleHotkeyAsk(): Promise<void> {
    // Suspend hotkeys while prompting
    this.hotkeyManager.suspend();

    try {
      const { question } = await inquirer.prompt([{
        type: 'input',
        name: 'question',
        message: 'Ask Claude:',
      }]);

      if (question?.trim()) {
        const answer = await this.askClaude(question);
        console.log(chalk.cyan(`\n💬 Claude: ${answer}\n`));
      }
    } finally {
      // Resume hotkeys after prompting
      this.hotkeyManager.resume();
    }
  }

  /**
   * Handle pivot hotkey (v) - opens pivot menu
   */
  private async handleHotkeyPivot(): Promise<void> {
    if (this.isPivoting) return;
    this.isPivoting = true;

    // Suspend hotkeys while in pivot menu
    this.hotkeyManager.suspend();

    try {
      const { pivotAction } = await inquirer.prompt([{
        type: 'list',
        name: 'pivotAction',
        message: 'Pivot Menu:',
        choices: [
          { name: '📋 Change story priority', value: 'priority' },
          { name: '➕ Add new story', value: 'add' },
          { name: '⏭️  Skip remaining stories', value: 'skip_rest' },
          { name: '🔄 Restart current story', value: 'restart' },
          { name: '❌ Cancel', value: 'cancel' },
        ],
      }]);

      switch (pivotAction) {
        case 'priority':
          await this.handlePivotPriority();
          break;
        case 'add':
          await this.handlePivotAddStory();
          break;
        case 'skip_rest':
          await this.handlePivotSkipRest();
          break;
        case 'restart':
          await this.handlePivotRestart();
          break;
        case 'cancel':
        default:
          console.log(chalk.dim('Pivot cancelled'));
          break;
      }
    } finally {
      this.isPivoting = false;
      this.hotkeyManager.resume();
    }
  }

  /**
   * Handle status hotkey (i)
   */
  private handleHotkeyStatus(): void {
    if (!this.state) {
      console.log(chalk.yellow('\nNo active session'));
      return;
    }

    const elapsed = (Date.now() - this.state.startTime.getTime()) / 1000 / 60;
    const progress = this.depManager.getProgress();

    console.log(chalk.blue('\n📊 Session Status'));
    console.log(`   Status: ${this.state.status}`);
    console.log(`   Elapsed: ${elapsed.toFixed(1)} minutes`);
    console.log(`   Current: ${this.state.currentStory?.title || 'None'}`);
    console.log(`   Progress: ${progress.complete}/${progress.total} stories`);
    console.log(`   Blocked: ${progress.blocked}`);
    console.log(`   Iterations: ${this.state.totalIterations}`);
    console.log('');
  }

  // ─────────────────────────────────────────────────────────────
  // Pivot Sub-handlers
  // ─────────────────────────────────────────────────────────────

  /**
   * Pivot: Change story priority
   */
  private async handlePivotPriority(): Promise<void> {
    const pendingStories = this.state?.feature.stories.filter(
      s => s.status === 'pending' || s.status === 'in_progress'
    ) || [];

    if (pendingStories.length === 0) {
      console.log(chalk.yellow('No pending stories to reorder'));
      return;
    }

    const { selectedStory } = await inquirer.prompt([{
      type: 'list',
      name: 'selectedStory',
      message: 'Select story to prioritize:',
      choices: pendingStories.map(s => ({
        name: `${s.id}: ${s.title}`,
        value: s.id,
      })),
    }]);

    // Mark story as high priority by clearing its dependencies
    this.depManager.clearDependencies(selectedStory);
    console.log(chalk.green(`✓ Story ${selectedStory} prioritized (dependencies cleared)`));
  }

  /**
   * Pivot: Add a new story
   */
  private async handlePivotAddStory(): Promise<void> {
    const { title, scope } = await inquirer.prompt([
      {
        type: 'input',
        name: 'title',
        message: 'Story title:',
      },
      {
        type: 'input',
        name: 'scope',
        message: 'Scope (comma-separated):',
      },
    ]);

    if (!title?.trim()) {
      console.log(chalk.yellow('Story title required'));
      return;
    }

    // Add to feature and dependency graph
    const newStory: Story = {
      id: `pivot-${Date.now()}`,
      title: title.trim(),
      scope: scope?.split(',').map((s: string) => s.trim()).filter(Boolean) || [],
      repos: [],
      status: 'pending',
    };

    if (this.state) {
      this.state.feature.stories.push(newStory);
      this.depManager.addNode(newStory.id);
      console.log(chalk.green(`✓ Story "${newStory.title}" added`));
    }
  }

  /**
   * Pivot: Skip all remaining stories
   */
  private async handlePivotSkipRest(): Promise<void> {
    const { confirm } = await inquirer.prompt([{
      type: 'confirm',
      name: 'confirm',
      message: 'Skip all remaining stories and end session?',
      default: false,
    }]);

    if (confirm && this.state) {
      this.state.status = 'completed';
      console.log(chalk.yellow('Skipping remaining stories...'));
    }
  }

  /**
   * Pivot: Restart current story
   */
  private async handlePivotRestart(): Promise<void> {
    if (!this.state?.currentStory) {
      console.log(chalk.yellow('No current story to restart'));
      return;
    }

    const { confirm } = await inquirer.prompt([{
      type: 'confirm',
      name: 'confirm',
      message: `Restart story "${this.state.currentStory.title}"?`,
      default: true,
    }]);

    if (confirm) {
      // Reset the story to pending state
      this.depManager.resetStory(this.state.currentStory.id);
      console.log(chalk.green(`✓ Story "${this.state.currentStory.title}" will restart`));
    }
  }
}
