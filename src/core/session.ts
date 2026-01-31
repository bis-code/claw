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

export interface SessionConfig {
  /** Maximum hours to run */
  maxHours: number;
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
  private iterationEngine: IterationEngine | null = null;
  private workingDir: string;
  private state: SessionState | null = null;

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
  }

  /**
   * Run a feature session
   */
  async run(feature: Feature, config: SessionConfig): Promise<SessionResult> {
    const startTime = new Date();
    const commits: string[] = [];
    const prs: number[] = [];

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
    console.log(chalk.dim(`   Budget: ${config.maxHours} hours`));
    console.log(chalk.dim(`   Stories: ${feature.stories.length}`));

    const deadline = new Date(startTime.getTime() + config.maxHours * 60 * 60 * 1000);

    try {
      // Main execution loop
      while (this.state.status === 'running') {
        // Check time budget
        if (new Date() >= deadline) {
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
      }
    } catch (error) {
      this.state.status = 'error';
      this.state.blockerReason = error instanceof Error ? error.message : String(error);
      console.log(chalk.red(`\n✗ Session error: ${this.state.blockerReason}`));
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
    const spinner = ora(`Executing: ${story.title}`).start();

    // Build prompt
    const prompt = this.claude.generateStoryPrompt(
      {
        title: story.title,
        scope: story.scope,
        repos: story.repos,
      },
      featureTitle
    );

    // Spawn options
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
   * Resume a paused session
   */
  async resume(feature: Feature, config: SessionConfig): Promise<SessionResult> {
    // For now, just restart - full resume would require checkpoint saving
    return this.run(feature, config);
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
}
