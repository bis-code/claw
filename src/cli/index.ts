#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Read package.json for version
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const packageJson = JSON.parse(readFileSync(join(__dirname, '../../package.json'), 'utf-8'));

const program = new Command();

program
  .name('claw')
  .description(packageJson.description)
  .version(packageJson.version, '-v, --version', 'Display version number');

// Main commands will be added here as we implement them

// claw init - Initialize workspace
program
  .command('init')
  .description('Initialize a claw workspace (auto-detect repos)')
  .option('-y, --yes', 'Accept detected configuration without prompts')
  .action(async (options) => {
    const { Workspace } = await import('../core/workspace.js');
    const inquirer = await import('inquirer');
    const ora = (await import('ora')).default;

    const workspace = new Workspace(process.cwd());

    // Check if already initialized
    if (workspace.isInitialized()) {
      console.log(chalk.yellow('⚠️  Workspace already initialized.'));
      console.log(chalk.dim(`Config: ${workspace.getConfigPath()}`));

      if (!options.yes) {
        const { overwrite } = await inquirer.default.prompt([{
          type: 'confirm',
          name: 'overwrite',
          message: 'Reinitialize workspace?',
          default: false,
        }]);
        if (!overwrite) return;
      }
    }

    // Detect repos
    const spinner = ora('Scanning for repositories...').start();
    const config = await workspace.init(false);
    spinner.succeed(`Found ${config.repos.length} repositories`);

    // Display detected structure
    console.log('\n' + chalk.blue('📂 Detected workspace structure:') + '\n');
    console.log(chalk.bold(`Workspace: ${config.name}\n`));

    console.log('Repos:');
    for (const repo of config.repos) {
      const typeIcon = {
        frontend: '🖥️',
        backend: '⚙️',
        shared: '📦',
        web3: '⛓️',
        monorepo: '📁',
        unknown: '❓',
      }[repo.type];

      console.log(`  ${typeIcon} ${repo.name} (${repo.type}${repo.framework ? `, ${repo.framework}` : ''}${repo.language ? `, ${repo.language}` : ''})`);
    }

    if (config.relationships.length > 0) {
      console.log('\nRelationships:');
      for (const rel of config.relationships) {
        console.log(`  ${rel.from} → ${rel.to} (${rel.type})`);
      }
    }

    // Confirm or skip based on --yes flag
    if (!options.yes) {
      console.log('');
      const { confirm } = await inquirer.default.prompt([{
        type: 'confirm',
        name: 'confirm',
        message: 'Is this correct?',
        default: true,
      }]);

      if (!confirm) {
        console.log(chalk.yellow('Aborted. Edit claw-workspace.json manually or run again.'));
        return;
      }
    }

    // Save config
    await workspace.save(config);
    console.log(chalk.green(`\n✓ Workspace initialized: ${workspace.getConfigPath()}`));
    console.log(chalk.dim('Run `claw feature "description"` to start a feature.'));
  });

// claw feature - Create and run a feature
program
  .command('feature <description>')
  .description('Start a new feature (interactive planning → autonomous execution)')
  .option('--plan-only', 'Only plan, do not execute')
  .option('--skip-discovery', 'Skip discovery phase')
  .option('--skip-breakdown', 'Skip interactive breakdown, create single story')
  .option('--hours <n>', 'Time budget in hours', '4')
  .action(async (desc, options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');
    const { BreakdownGenerator } = await import('../core/breakdown.js');
    const { StoryRefiner } = await import('../core/refinement.js');
    const { DiscoveryEngine } = await import('../core/discovery.js');
    const inquirer = await import('inquirer');
    const ora = (await import('ora')).default;

    // Load workspace config
    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    console.log(chalk.blue(`\n📋 Feature: "${desc}"\n`));

    // Run discovery unless skipped
    let findings;
    if (!options.skipDiscovery) {
      const discoverySpinner = ora('Running discovery...').start();
      const discoveryEngine = new DiscoveryEngine(process.cwd());
      const results = await discoveryEngine.runDiscovery({
        mode: 'shallow',
        repos: config.repos,
      });
      findings = results.flatMap(r => r.findings);
      discoverySpinner.succeed(`Discovery complete: ${findings.length} findings`);
    }

    // Generate breakdown options unless skipped
    if (!options.skipBreakdown) {
      const breakdownSpinner = ora('Generating breakdown options...').start();
      const breakdownGenerator = new BreakdownGenerator(process.cwd());

      const approaches = await breakdownGenerator.generateApproaches({
        featureTitle: desc,
        featureDescription: desc,
        repos: config.repos,
        findings,
      });
      breakdownSpinner.succeed(`Generated ${approaches.length} approaches`);

      // Display approaches
      console.log(chalk.blue('\n💬 How should we structure this feature?\n'));

      for (let i = 0; i < approaches.length; i++) {
        const a = approaches[i];
        const marker = a.recommended ? chalk.green(' (Recommended)') : '';
        console.log(chalk.bold(`[${i + 1}] ${a.name}${marker}`));
        console.log(chalk.dim(`    ${a.description}`));
        console.log(chalk.dim(`    Stories: ${a.stories.length}, Est: ${a.estimatedHours}h`));
        console.log('');
      }

      // Let user select
      const { approachIndex } = await inquirer.default.prompt([{
        type: 'list',
        name: 'approachIndex',
        message: 'Select an approach:',
        choices: [
          ...approaches.map((a, i) => ({
            name: `${a.name}${a.recommended ? ' (Recommended)' : ''} - ${a.stories.length} stories`,
            value: i,
          })),
          { name: 'Custom breakdown...', value: -1 },
        ],
      }]);

      if (approachIndex === -1) {
        console.log(chalk.yellow('Custom breakdown not yet implemented. Using first approach.'));
      }

      const selectedApproach = approaches[approachIndex >= 0 ? approachIndex : 0];
      console.log(chalk.green(`\n✓ Selected: ${selectedApproach.name}\n`));

      // Refine stories interactively
      const refiner = new StoryRefiner();
      const { refineInteractively } = await inquirer.default.prompt([{
        type: 'confirm',
        name: 'refineInteractively',
        message: 'Refine stories interactively? (modify scope, split, skip)',
        default: false,
      }]);

      let refinedStories = selectedApproach.stories;
      if (refineInteractively) {
        refinedStories = await refiner.refineStories(selectedApproach.stories);
      } else {
        // Quick refinement - show all and accept
        refinedStories = await refiner.quickRefine(selectedApproach.stories);
      }

      if (refinedStories.length === 0) {
        console.log(chalk.yellow('\n⚠️  All stories skipped. Aborting feature creation.'));
        return;
      }

      // Show final stories
      console.log(chalk.blue('\n📋 Final Stories:'));
      for (const story of refinedStories) {
        console.log(`  ${chalk.dim('•')} ${story.title} (${story.estimatedHours}h)`);
        if (story.dependsOn && story.dependsOn.length > 0) {
          console.log(chalk.dim(`      Depends on: ${story.dependsOn.join(', ')}`));
        }
      }

      // Initialize feature manager and create feature with stories
      const featureManager = new FeatureManager(
        config.obsidian?.vault || '~/Documents/Obsidian',
        config.obsidian?.project || `Projects/${config.name}`
      );

      const feature = await featureManager.create(desc);

      // Update with selected stories (simplified - would need to update feature.ts)
      console.log(chalk.green(`\n✓ Feature created: ${feature.id}`));
      console.log(chalk.dim(`  Obsidian: ${config.obsidian?.project}/features/${feature.id}/_overview.md`));

    } else {
      // Simple single-story feature
      const featureManager = new FeatureManager(
        config.obsidian?.vault || '~/Documents/Obsidian',
        config.obsidian?.project || `Projects/${config.name}`
      );

      const feature = await featureManager.create(desc);
      console.log(chalk.green(`✓ Feature created: ${feature.id}`));
    }

    if (options.planOnly) {
      console.log(chalk.dim('\n--plan-only specified. Stopping here.'));
      console.log(chalk.dim('Run `claw run` to execute.'));
      return;
    }

    // Execution would happen here (Epic 3)
    console.log(chalk.yellow('\n⚠️  Autonomous execution not yet implemented (Epic 3).'));
    console.log(chalk.dim('Run `claw run` when ready.'));
  });

// claw run - Execute pending stories
program
  .command('run [feature]')
  .description('Run pending stories autonomously')
  .option('--hours <n>', 'Time budget in hours', '4')
  .option('--stories <n>', 'Max stories to complete')
  .option('--until-blocked', 'Stop at first blocker')
  .option('--pause-between', 'Pause between stories for review')
  .option('--model <model>', 'Claude model to use (sonnet, opus, haiku)', 'sonnet')
  .option('-y, --yes', 'Skip permission prompts')
  .option('--retry', 'Enable iteration-until-green mode (retry on failure)')
  .option('--max-retries <n>', 'Max retries per story', '5')
  .option('--pr', 'Create PR after all stories complete')
  .option('--pr-per-story', 'Create PR after each story (advanced)')
  .action(async (featureId, options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');
    const { SessionRunner } = await import('../core/session.js');

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const featureManager = new FeatureManager(
      config.obsidian?.vault || '~/Documents/Obsidian',
      config.obsidian?.project || `Projects/${config.name}`
    );

    // Get feature to run
    let feature;
    if (featureId) {
      feature = await featureManager.get(featureId);
      if (!feature) {
        console.log(chalk.red(`✗ Feature not found: ${featureId}`));
        process.exit(1);
      }
    } else {
      // Get most recent feature with pending stories
      const features = await featureManager.list();
      feature = features.find(f => f.status !== 'complete');
      if (!feature) {
        console.log(chalk.yellow('No features with pending stories.'));
        console.log(chalk.dim('Run `claw feature "description"` to create one.'));
        return;
      }
    }

    // Initialize session runner
    const runner = new SessionRunner(
      process.cwd(),
      config.obsidian?.vault || '~/Documents/Obsidian',
      config.obsidian?.project || `Projects/${config.name}`
    );

    // Run session
    const result = await runner.run(feature, {
      maxHours: parseFloat(options.hours),
      maxStories: options.stories ? parseInt(options.stories, 10) : undefined,
      stopOnBlocker: options.untilBlocked,
      pauseBetweenStories: options.pauseBetween,
      model: options.model as 'sonnet' | 'opus' | 'haiku',
      dangerouslySkipPermissions: options.yes,
      iterateUntilGreen: options.retry,
      maxIterations: options.maxRetries ? parseInt(options.maxRetries, 10) : 5,
      createPROnComplete: options.pr,
      createPRPerStory: options.prPerStory,
    });

    if (!result.success) {
      console.log(chalk.yellow(`\nSession ended: ${result.error || 'incomplete'}`));
      process.exit(1);
    }
  });

// claw resume - Resume from last state
program
  .command('resume [feature]')
  .description('Resume work on a feature from last checkpoint')
  .option('--hours <hours>', 'Time budget in hours', parseFloat)
  .option('--stories <count>', 'Max stories to complete', parseInt)
  .option('--model <model>', 'Claude model to use', 'sonnet')
  .action(async (featureArg, options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');
    const { SessionRunner } = await import('../core/session.js');
    const { CheckpointManager } = await import('../core/checkpoint.js');

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const vaultPath = config.obsidian?.vault || '~/Documents/Obsidian';
    const projectPath = config.obsidian?.project || `Projects/${config.name}`;
    const featureManager = new FeatureManager(vaultPath, projectPath);
    const checkpointManager = new CheckpointManager(vaultPath, projectPath);

    // Find feature with checkpoint
    let featureId = featureArg;

    if (!featureId) {
      // List features with checkpoints
      const features = await featureManager.list();
      const resumable: { id: string; title: string; checkpoint: import('../core/checkpoint.js').CheckpointData }[] = [];

      for (const f of features) {
        const checkpoint = await checkpointManager.loadCheckpoint(f.id);
        if (checkpoint && checkpointManager.isResumable(checkpoint)) {
          resumable.push({ id: f.id, title: f.title, checkpoint });
        }
      }

      if (resumable.length === 0) {
        console.log(chalk.yellow('No resumable sessions found.'));
        console.log(chalk.dim('Start a new session with: claw run <feature>'));
        process.exit(0);
      }

      if (resumable.length === 1) {
        featureId = resumable[0].id;
        console.log(chalk.blue(`Found 1 resumable session: "${resumable[0].title}"`));
      } else {
        // Multiple resumable sessions - prompt user
        const inquirer = await import('inquirer');
        const { selected } = await inquirer.default.prompt([{
          type: 'list',
          name: 'selected',
          message: 'Select session to resume:',
          choices: resumable.map(r => ({
            name: `${r.title} (${r.checkpoint.sessionState.storiesCompleted}/${Object.keys(r.checkpoint.storyProgress).length} stories)`,
            value: r.id,
          })),
        }]);
        featureId = selected;
      }
    }

    // Load feature and checkpoint
    const feature = await featureManager.get(featureId);
    if (!feature) {
      console.log(chalk.red(`✗ Feature not found: ${featureId}`));
      process.exit(1);
    }

    const checkpoint = await checkpointManager.loadCheckpoint(featureId);
    if (!checkpoint) {
      console.log(chalk.yellow(`No checkpoint found for "${feature.title}".`));
      console.log(chalk.dim('Starting fresh session instead.'));
    } else {
      console.log(chalk.blue(`\n📂 Resuming: "${feature.title}"`));
      console.log(chalk.dim(`   Previous status: ${checkpoint.sessionState.status}`));
      console.log(chalk.dim(`   Stories completed: ${checkpoint.sessionState.storiesCompleted}`));
      console.log(chalk.dim(`   Remaining time: ${checkpointManager.getRemainingTime(checkpoint).toFixed(1)}h`));
    }

    // Create session runner and resume
    const sessionRunner = new SessionRunner(process.cwd(), vaultPath, projectPath);
    const result = await sessionRunner.resume(feature, {
      maxHours: options.hours,
      maxStories: options.stories,
      model: options.model,
    });

    if (result.success) {
      console.log(chalk.green('\n✓ Session completed successfully!'));
      process.exit(0);
    } else {
      console.log(chalk.yellow(`\nSession ended: ${result.error || 'incomplete'}`));
      process.exit(1);
    }
  });

// claw status - Show current state
program
  .command('status [feature]')
  .description('Show workspace or feature status')
  .action(async (featureId) => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const featureManager = new FeatureManager(
      config.obsidian?.vault || '~/Documents/Obsidian',
      config.obsidian?.project || `Projects/${config.name}`
    );

    if (featureId) {
      // Show specific feature
      const feature = await featureManager.get(featureId);
      if (!feature) {
        console.log(chalk.red(`✗ Feature not found: ${featureId}`));
        process.exit(1);
      }

      console.log(chalk.blue(`\n📋 Feature: ${feature.title}\n`));
      console.log(`  ID: ${feature.id}`);
      console.log(`  Status: ${feature.status}`);
      console.log(`  Created: ${feature.createdAt.toISOString()}`);
      console.log('\n  Stories:');
      for (const story of feature.stories) {
        const emoji = { pending: '⏳', in_progress: '🔄', complete: '✅', blocked: '🚫', skipped: '⏭️' }[story.status];
        console.log(`    ${emoji} ${story.id}. ${story.title} (${story.status})`);
      }
    } else {
      // Show workspace overview
      console.log(chalk.blue(`\n📊 Workspace: ${config.name}\n`));
      console.log(`  Repos: ${config.repos.length}`);
      for (const repo of config.repos) {
        console.log(`    - ${repo.name} (${repo.type})`);
      }

      const features = await featureManager.list();
      console.log(`\n  Features: ${features.length}`);
      for (const f of features.slice(0, 5)) {
        const emoji = { planning: '📝', executing: '🔄', complete: '✅', paused: '⏸️' }[f.status];
        console.log(`    ${emoji} ${f.id} - ${f.title}`);
      }
      if (features.length > 5) {
        console.log(chalk.dim(`    ... and ${features.length - 5} more`));
      }
    }
  });

// claw list - List all features
program
  .command('list')
  .alias('ls')
  .description('List all features and their status')
  .action(async () => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const featureManager = new FeatureManager(
      config.obsidian?.vault || '~/Documents/Obsidian',
      config.obsidian?.project || `Projects/${config.name}`
    );

    const features = await featureManager.list();

    if (features.length === 0) {
      console.log(chalk.dim('No features yet. Run `claw feature "description"` to create one.'));
      return;
    }

    console.log(chalk.blue('\n📋 Features\n'));

    for (const f of features) {
      const emoji = { planning: '📝', executing: '🔄', complete: '✅', paused: '⏸️' }[f.status];
      const progress = `${f.stories.filter(s => s.status === 'complete').length}/${f.stories.length}`;
      console.log(`  ${emoji} ${f.id}`);
      console.log(chalk.dim(`     ${f.title} (${progress} stories)`));
    }
  });

// claw pivot - Pivot menu
program
  .command('pivot <feature>')
  .description('Open pivot menu for a feature (re-scope, reorder, add/remove)')
  .action(async (feature) => {
    console.log(chalk.blue(`🔄 Pivot: ${feature}`));
    console.log(chalk.yellow('Not yet implemented - Epic 4, Story 4.3'));
  });

// claw ask - Ask Claude about a feature
program
  .command('ask <feature> <question>')
  .description('Ask Claude a question about a feature')
  .action(async (feature, question) => {
    console.log(chalk.blue(`❓ Asking about ${feature}: "${question}"`));
    console.log(chalk.yellow('Not yet implemented - Epic 4, Story 4.2'));
  });

// claw discover - Run discovery agents
program
  .command('discover')
  .description('Run discovery agents to find work in the codebase')
  .option('-m, --mode <mode>', 'Discovery mode: shallow, balanced, deep', 'balanced')
  .option('-f, --focus <area>', 'Focus on specific area')
  .action(async (options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { DiscoveryEngine } = await import('../core/discovery.js');
    const ora = (await import('ora')).default;

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const engine = new DiscoveryEngine(process.cwd());

    console.log(chalk.blue(`\n🔍 Running ${options.mode} discovery...\n`));

    const spinner = ora('Scanning codebase...').start();

    const results = await engine.runDiscovery({
      mode: options.mode,
      focus: options.focus,
      repos: config.repos,
    });

    spinner.stop();

    // Display results
    let totalFindings = 0;
    for (const result of results) {
      if (result.findings.length === 0) continue;

      console.log(chalk.bold(`\n${result.agent.toUpperCase()} (${result.findings.length} findings)`));

      for (const finding of result.findings) {
        const priorityColors: Record<string, typeof chalk.red> = {
          P0: chalk.red,
          P1: chalk.yellow,
          P2: chalk.blue,
          P3: chalk.dim,
        };
        const color = priorityColors[finding.priority] || chalk.white;

        console.log(`  ${color(`[${finding.priority}]`)} ${finding.title}`);
        if (finding.file) {
          console.log(chalk.dim(`       ${finding.file}${finding.line ? `:${finding.line}` : ''}`));
        }
        totalFindings++;
      }
    }

    if (totalFindings === 0) {
      console.log(chalk.green('✓ No significant issues found!'));
    } else {
      console.log(chalk.dim(`\nTotal: ${totalFindings} findings`));
      console.log(chalk.dim('Run `claw feature` to create stories from these findings.'));
    }
  });

// claw validate - Validate workspace configuration
program
  .command('validate')
  .description('Validate workspace configuration and features')
  .option('-f, --feature <id>', 'Validate a specific feature')
  .action(async (options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');
    const {
      validateWorkspaceConfig,
      validateFeature,
      formatValidationResult,
    } = await import('../core/validation.js');

    console.log(chalk.blue('🔍 Validating configuration...\n'));

    // Validate workspace
    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    console.log(chalk.bold('Workspace Configuration:'));
    const workspaceResult = validateWorkspaceConfig(config);
    console.log(formatValidationResult(workspaceResult));

    // Validate specific feature or all features
    if (options.feature) {
      const featureManager = new FeatureManager(
        config.obsidian?.vault || '~/Documents/Obsidian',
        config.obsidian?.project || `Projects/${config.name}`
      );

      const feature = await featureManager.get(options.feature);
      if (!feature) {
        console.log(chalk.red(`\n✗ Feature not found: ${options.feature}`));
        process.exit(1);
      }

      console.log(chalk.bold(`\nFeature: ${feature.title}`));
      const featureResult = validateFeature(feature);
      console.log(formatValidationResult(featureResult));

      if (!workspaceResult.valid || !featureResult.valid) {
        process.exit(1);
      }
    } else if (!workspaceResult.valid) {
      process.exit(1);
    }

    console.log(chalk.green('\n✓ Validation complete'));
  });

// claw doctor - Diagnose common issues
program
  .command('doctor')
  .description('Diagnose common setup issues')
  .action(async () => {
    console.log(chalk.blue('🩺 Running diagnostics...\n'));

    const checks: { name: string; check: () => Promise<boolean>; fix?: string }[] = [
      {
        name: 'Git installed',
        check: async () => {
          try {
            const { execSync } = await import('child_process');
            execSync('git --version', { stdio: 'pipe' });
            return true;
          } catch { return false; }
        },
        fix: 'Install git from https://git-scm.com',
      },
      {
        name: 'Claude CLI (claude) installed',
        check: async () => {
          try {
            const { execSync } = await import('child_process');
            execSync('which claude', { stdio: 'pipe' });
            return true;
          } catch { return false; }
        },
        fix: 'Install Claude CLI: npm install -g @anthropic-ai/claude-code',
      },
      {
        name: 'GitHub CLI (gh) installed',
        check: async () => {
          try {
            const { execSync } = await import('child_process');
            execSync('which gh', { stdio: 'pipe' });
            return true;
          } catch { return false; }
        },
        fix: 'Install GitHub CLI: brew install gh',
      },
      {
        name: 'Workspace initialized',
        check: async () => {
          const { existsSync } = await import('fs');
          return existsSync('claw-workspace.json');
        },
        fix: 'Run: claw init',
      },
      {
        name: 'Obsidian vault accessible',
        check: async () => {
          try {
            const { existsSync } = await import('fs');
            const { Workspace } = await import('../core/workspace.js');
            const workspace = new Workspace(process.cwd());
            const config = await workspace.load();
            if (!config?.obsidian?.vault) return false;
            const vaultPath = config.obsidian.vault.replace('~', process.env.HOME || '');
            return existsSync(vaultPath);
          } catch { return false; }
        },
        fix: 'Check obsidian.vault path in claw-workspace.json',
      },
    ];

    let allPassed = true;
    for (const { name, check, fix } of checks) {
      const passed = await check();
      if (passed) {
        console.log(chalk.green(`  ✓ ${name}`));
      } else {
        console.log(chalk.red(`  ✗ ${name}`));
        if (fix) {
          console.log(chalk.dim(`    → ${fix}`));
        }
        allPassed = false;
      }
    }

    console.log('');
    if (allPassed) {
      console.log(chalk.green('All checks passed!'));
    } else {
      console.log(chalk.yellow('Some checks failed. Please fix the issues above.'));
      process.exit(1);
    }
  });

// Parse and run
program.parse();
