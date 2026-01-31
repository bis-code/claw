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
  .option('--hours <n>', 'Time budget in hours', '4')
  .action(async (desc, options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');
    const ora = (await import('ora')).default;

    // Load workspace config
    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    // Initialize feature manager
    const featureManager = new FeatureManager(
      config.obsidian?.vault || '~/Documents/Obsidian',
      config.obsidian?.project || `Projects/${config.name}`
    );

    // Create feature
    const spinner = ora(`Creating feature: "${desc}"`).start();
    const feature = await featureManager.create(desc);
    spinner.succeed(`Feature created: ${feature.id}`);

    console.log('\n' + chalk.blue('📋 Feature Overview:') + '\n');
    console.log(`  Title: ${feature.title}`);
    console.log(`  Status: ${feature.status}`);
    console.log(`  Stories: ${feature.stories.length}`);
    console.log(`  Obsidian: ${config.obsidian?.project}/features/${feature.id}/_overview.md`);

    if (options.planOnly) {
      console.log(chalk.dim('\n--plan-only specified. Stopping here.'));
      console.log(chalk.dim('Run `claw run` to execute, or `claw feature` again for interactive breakdown (Epic 2).'));
      return;
    }

    // For now, just show that execution would happen
    console.log(chalk.yellow('\n⚠️  Autonomous execution not yet implemented (Epic 3).'));
    console.log(chalk.dim('Run `claw run` when ready, or wait for Epic 3 implementation.'));
  });

// claw run - Execute pending stories
program
  .command('run')
  .description('Run pending stories autonomously')
  .option('--hours <n>', 'Time budget in hours', '4')
  .option('--stories <n>', 'Max stories to complete')
  .option('--until-blocked', 'Stop at first blocker')
  .action(async (options) => {
    console.log(chalk.blue('🤖 Starting autonomous execution...'));
    console.log(chalk.yellow('Not yet implemented - Epic 3'));
  });

// claw resume - Resume from last state
program
  .command('resume [feature]')
  .description('Resume work on a feature from last checkpoint')
  .action(async (feature) => {
    console.log(chalk.blue(`📂 Resuming${feature ? `: ${feature}` : '...'}}`));
    console.log(chalk.yellow('Not yet implemented - Epic 4, Story 4.4'));
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

// Parse and run
program.parse();
