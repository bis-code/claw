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

      // Show stories
      console.log(chalk.blue('Stories:'));
      for (const story of selectedApproach.stories) {
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

// Parse and run
program.parse();
