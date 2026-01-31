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
    console.log(chalk.blue(`📋 Feature: "${desc}"`));
    console.log(chalk.yellow('Not yet implemented - Epic 2'));
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
  .action(async (feature) => {
    console.log(chalk.blue('📊 Status'));
    console.log(chalk.yellow('Not yet implemented'));
  });

// claw list - List all features
program
  .command('list')
  .alias('ls')
  .description('List all features and their status')
  .action(async () => {
    console.log(chalk.blue('📋 Features'));
    console.log(chalk.yellow('Not yet implemented'));
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
