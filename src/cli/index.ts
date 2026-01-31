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
    console.log(chalk.blue('🔍 Detecting workspace...'));
    console.log(chalk.yellow('Not yet implemented - Epic 1, Story 1.2'));
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
