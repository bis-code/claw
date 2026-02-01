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

// claw new - Create a new project from scratch
program
  .command('new <name>')
  .description('Create a new project with full setup (repo, Obsidian, GitHub)')
  .option('--no-github', 'Skip GitHub repo creation')
  .option('--private', 'Create private GitHub repo')
  .option('-p, --path <dir>', 'Parent directory for project', '.')
  .action(async (name, options) => {
    const { execSync, spawnSync } = await import('child_process');
    const { mkdir, writeFile } = await import('fs/promises');
    const { join } = await import('path');
    const { existsSync } = await import('fs');
    const { homedir } = await import('os');
    const inquirerModule = await import('inquirer');
    const inquirerPrompt = inquirerModule.default.prompt;

    console.log(chalk.blue(`\n🚀 Creating new project: ${name}\n`));

    // Step 1: Check prerequisites
    console.log(chalk.dim('Checking prerequisites...'));

    const checks = [
      { cmd: 'git --version', name: 'git' },
      { cmd: 'gh --version', name: 'GitHub CLI (gh)' },
    ];

    for (const check of checks) {
      try {
        execSync(check.cmd, { stdio: 'pipe' });
        console.log(chalk.green(`  ✓ ${check.name}`));
      } catch {
        console.log(chalk.red(`  ✗ ${check.name} not found`));
        console.log(chalk.dim(`    Install: ${check.name === 'git' ? 'https://git-scm.com' : 'brew install gh'}`));
        process.exit(1);
      }
    }

    // Step 2: Get available GitHub accounts
    interface GitHubAccount {
      username: string;
      email: string;
      name: string;
    }

    const accounts: GitHubAccount[] = [];
    let selectedAccount: GitHubAccount | null = null;

    if (options.github !== false) {
      console.log(chalk.dim('\nChecking GitHub accounts...'));

      try {
        // Get all authenticated accounts
        const authStatus = execSync('gh auth status 2>&1', { encoding: 'utf-8' });

        // Parse accounts from auth status (matches "Logged in to github.com account USERNAME")
        const accountMatches = authStatus.matchAll(/Logged in to github\.com account (\S+)/g);

        for (const match of accountMatches) {
          const username = match[1];
          try {
            // Get user details from GitHub API
            const userJson = execSync(`gh api users/${username}`, { encoding: 'utf-8' });
            const user = JSON.parse(userJson);

            // Try to get email from GitHub API (might be null if private)
            let email = user.email || '';
            if (!email) {
              // Try to get from user's commits API
              try {
                const commitsJson = execSync(`gh api users/${username}/events/public --jq '.[].payload.commits[]?.author.email' 2>/dev/null | head -1`, { encoding: 'utf-8' });
                email = commitsJson.trim() || `${username}@users.noreply.github.com`;
              } catch {
                email = `${username}@users.noreply.github.com`;
              }
            }

            accounts.push({
              username,
              email,
              name: user.name || username,
            });
            console.log(chalk.green(`  ✓ Found account: ${username} (${user.name || 'No name'})`));
          } catch {
            // Fallback if API fails
            accounts.push({
              username,
              email: `${username}@users.noreply.github.com`,
              name: username,
            });
            console.log(chalk.green(`  ✓ Found account: ${username}`));
          }
        }

        if (accounts.length === 0) {
          console.log(chalk.yellow('  ⚠ No GitHub accounts found'));
          const { login } = await inquirerPrompt([{
            type: 'confirm',
            name: 'login',
            message: 'Login to GitHub now?',
            default: true,
          }]);

          if (login) {
            spawnSync('gh', ['auth', 'login'], { stdio: 'inherit' });
            console.log(chalk.dim('Please re-run `claw new` after login.'));
            process.exit(0);
          } else {
            options.github = false;
          }
        } else if (accounts.length === 1) {
          selectedAccount = accounts[0];
          console.log(chalk.dim(`\nUsing account: ${selectedAccount.username}`));
        } else {
          // Multiple accounts - let user choose
          const { accountChoice } = await inquirerPrompt([{
            type: 'list',
            name: 'accountChoice',
            message: 'Which GitHub account should own this project?',
            choices: accounts.map(a => ({
              name: `${a.username} (${a.name}) - ${a.email}`,
              value: a.username,
            })),
          }]);
          selectedAccount = accounts.find(a => a.username === accountChoice) || accounts[0];
        }
      } catch {
        console.log(chalk.yellow('  ⚠ Could not check GitHub accounts'));
        options.github = false;
      }
    }

    // Step 3: Create project directory
    const projectPath = join(options.path === '.' ? process.cwd() : options.path, name);
    console.log(chalk.dim(`\nCreating project at ${projectPath}...`));

    if (existsSync(projectPath)) {
      console.log(chalk.red(`  ✗ Directory already exists: ${projectPath}`));
      process.exit(1);
    }

    await mkdir(projectPath, { recursive: true });
    console.log(chalk.green(`  ✓ Created directory`));

    // Step 4: Initialize git with selected account's identity
    console.log(chalk.dim('\nInitializing git repository...'));
    execSync('git init', { cwd: projectPath, stdio: 'pipe' });

    // Use selected GitHub account or prompt for identity
    let gitEmail: string;
    let gitName: string;

    if (selectedAccount) {
      // Confirm or override the account's identity
      const { useAccountIdentity } = await inquirerPrompt([{
        type: 'confirm',
        name: 'useAccountIdentity',
        message: `Use git identity: ${selectedAccount.name} <${selectedAccount.email}>?`,
        default: true,
      }]);

      if (useAccountIdentity) {
        gitEmail = selectedAccount.email;
        gitName = selectedAccount.name;
      } else {
        const answers = await inquirerPrompt([
          {
            type: 'input',
            name: 'gitEmail',
            message: 'Git email:',
            default: selectedAccount.email,
          },
          {
            type: 'input',
            name: 'gitName',
            message: 'Git name:',
            default: selectedAccount.name,
          },
        ]);
        gitEmail = answers.gitEmail;
        gitName = answers.gitName;
      }
    } else {
      // No GitHub account, ask for identity manually
      let defaultEmail = '';
      let defaultName = '';
      try {
        defaultEmail = execSync('git config --global user.email', { encoding: 'utf-8' }).trim();
        defaultName = execSync('git config --global user.name', { encoding: 'utf-8' }).trim();
      } catch {
        // Global config not set
      }

      const answers = await inquirerPrompt([
        {
          type: 'input',
          name: 'gitEmail',
          message: 'Git email for this project:',
          default: defaultEmail,
          validate: (v: string) => v.includes('@') ? true : 'Enter a valid email',
        },
        {
          type: 'input',
          name: 'gitName',
          message: 'Git name for this project:',
          default: defaultName,
          validate: (v: string) => v.length > 0 ? true : 'Name is required',
        },
      ]);
      gitEmail = answers.gitEmail;
      gitName = answers.gitName;
    }

    execSync(`git config user.email "${gitEmail}"`, { cwd: projectPath, stdio: 'pipe' });
    execSync(`git config user.name "${gitName}"`, { cwd: projectPath, stdio: 'pipe' });
    console.log(chalk.green(`  ✓ Git initialized (${gitEmail})`));

    // Step 5: Ask user to describe the project structure
    console.log(chalk.blue('\n📁 Project Structure\n'));

    const { structureChoice } = await inquirerPrompt([{
      type: 'list',
      name: 'structureChoice',
      message: 'How would you like to set up the project?',
      choices: [
        { name: 'Describe it (Claude will scaffold based on your description)', value: 'describe' },
        { name: 'TypeScript (quick start)', value: 'typescript' },
        { name: 'Python (quick start)', value: 'python' },
        { name: 'Go (quick start)', value: 'go' },
        { name: 'Minimal (just .gitignore and README)', value: 'minimal' },
      ],
    }]);

    if (structureChoice === 'describe') {
      // User describes what they want
      const { projectDescription } = await inquirerPrompt([{
        type: 'input',
        name: 'projectDescription',
        message: 'Describe your project (e.g., "Next.js app with Tailwind, Prisma, and tRPC"):\n',
      }]);

      console.log(chalk.dim('\n📝 Project description saved.'));
      console.log(chalk.dim('Run `claude` in the project directory and ask it to scaffold based on this description:\n'));
      console.log(chalk.cyan(`  "${projectDescription}"`));
      console.log('');

      // Create minimal structure with description
      await writeFile(join(projectPath, '.gitignore'), 'node_modules/\ndist/\nbuild/\n.env\n.env.local\n*.log\n');
      await writeFile(join(projectPath, 'README.md'), `# ${name}\n\n## Project Description\n\n${projectDescription}\n\n## Getting Started\n\nRun \`claude\` and ask it to scaffold this project based on the description above.\n`);
      await writeFile(join(projectPath, 'PROJECT_SPEC.md'), `# Project Specification\n\n${projectDescription}\n\n## Instructions for Claude\n\nPlease scaffold this project with:\n- Appropriate directory structure\n- Package configuration\n- Basic setup files\n- Development tooling\n`);

      console.log(chalk.green('  ✓ Created PROJECT_SPEC.md with your description'));
    } else if (structureChoice === 'minimal') {
      await writeFile(join(projectPath, '.gitignore'), 'node_modules/\ndist/\nbuild/\n.env\n.env.local\n*.log\n');
      await writeFile(join(projectPath, 'README.md'), `# ${name}\n\nCreated with [claw](https://github.com/bis-code/claw).\n`);
      console.log(chalk.green('  ✓ Minimal structure created'));
    } else {
      // Quick start templates
      const templates: Record<string, () => Promise<void>> = {
        typescript: async () => {
          await writeFile(join(projectPath, 'package.json'), JSON.stringify({
            name,
            version: '0.1.0',
            type: 'module',
            scripts: {
              build: 'tsc',
              dev: 'tsc --watch',
              test: 'jest',
            },
          }, null, 2));
          await writeFile(join(projectPath, 'tsconfig.json'), JSON.stringify({
            compilerOptions: {
              target: 'ES2022',
              module: 'ESNext',
              moduleResolution: 'node',
              esModuleInterop: true,
              strict: true,
              outDir: 'dist',
            },
            include: ['src'],
          }, null, 2));
          await mkdir(join(projectPath, 'src'));
          await writeFile(join(projectPath, 'src', 'index.ts'), '// Entry point\n\nconsole.log("Hello, world!");\n');
          await writeFile(join(projectPath, '.gitignore'), 'node_modules/\ndist/\n.env\n');
        },
        go: async () => {
          await writeFile(join(projectPath, 'go.mod'), `module ${name}\n\ngo 1.21\n`);
          await writeFile(join(projectPath, 'main.go'), `package main\n\nimport "fmt"\n\nfunc main() {\n\tfmt.Println("Hello, world!")\n}\n`);
          await writeFile(join(projectPath, '.gitignore'), `${name}\n*.exe\n.env\n`);
        },
        python: async () => {
          await writeFile(join(projectPath, 'requirements.txt'), '# Add dependencies here\n');
          await writeFile(join(projectPath, 'main.py'), '#!/usr/bin/env python3\n\ndef main():\n    print("Hello, world!")\n\nif __name__ == "__main__":\n    main()\n');
          await writeFile(join(projectPath, '.gitignore'), '__pycache__/\n*.pyc\nvenv/\n.env\n');
          await mkdir(join(projectPath, 'src'));
          await writeFile(join(projectPath, 'src', '__init__.py'), '');
        },
      };

      await templates[structureChoice]();
      console.log(chalk.green(`  ✓ ${structureChoice} template created`));
    }

    // Step 6: Create README if not already created
    const readmePath = join(projectPath, 'README.md');
    if (!existsSync(readmePath)) {
      await writeFile(readmePath, `# ${name}\n\nCreated with [claw](https://github.com/bis-code/claw).\n\n## Getting Started\n\nTODO: Add setup instructions.\n`);
    }

    // Step 7: Create initial commit
    execSync('git add -A', { cwd: projectPath, stdio: 'pipe' });
    execSync('git commit -m "Initial commit\n\n🤖 Generated with claw"', { cwd: projectPath, stdio: 'pipe' });
    console.log(chalk.green(`  ✓ Initial commit created`));

    // Step 8: Create GitHub repo under selected account
    if (options.github !== false && selectedAccount) {
      console.log(chalk.dim(`\nCreating GitHub repository under ${selectedAccount.username}...`));
      try {
        const visibility = options.private ? '--private' : '--public';
        // Use full repo path with username to ensure correct account
        const repoName = `${selectedAccount.username}/${name}`;
        execSync(`gh repo create ${repoName} ${visibility} --source . --remote origin --push`, {
          cwd: projectPath,
          stdio: 'pipe',
        });
        console.log(chalk.green(`  ✓ GitHub repo created: ${repoName}`));
      } catch (error) {
        console.log(chalk.yellow(`  ⚠ Failed to create GitHub repo: ${error instanceof Error ? error.message : error}`));
        console.log(chalk.dim('    You can create it manually: gh repo create'));
      }
    }

    // Step 9: Create Obsidian project folder
    const obsidianVault = join(homedir(), 'Documents', 'Obsidian');
    const obsidianProject = join(obsidianVault, 'Projects', name);

    if (existsSync(obsidianVault)) {
      console.log(chalk.dim('\nCreating Obsidian project folder...'));
      await mkdir(join(obsidianProject, 'features'), { recursive: true });
      await writeFile(join(obsidianProject, '_index.md'), `# ${name}\n\nProject created: ${new Date().toISOString().split('T')[0]}\n\n## Features\n\n- Use \`claw feature\` to create features\n\n## Notes\n\n`);
      console.log(chalk.green(`  ✓ Obsidian folder created`));
    } else {
      console.log(chalk.dim('\nObsidian vault not found, skipping folder creation.'));
    }

    // Step 10: Initialize claw workspace
    console.log(chalk.dim('\nInitializing claw workspace...'));
    const { Workspace } = await import('../core/workspace.js');
    const workspace = new Workspace(projectPath);
    await workspace.init(false);
    console.log(chalk.green(`  ✓ claw workspace initialized`));

    // Done!
    console.log(chalk.green(`\n✅ Project "${name}" created successfully!\n`));
    console.log(chalk.bold('Next steps:'));
    console.log(chalk.dim(`  cd ${name}`));
    console.log(chalk.dim('  claw feature "my first feature"'));
    console.log(chalk.dim('  claw run --hours 4'));
  });

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

      // Ask about Claude permissions
      console.log(chalk.blue('\n🔒 Claude Permissions'));
      console.log(chalk.dim('What should Claude be allowed to do autonomously?\n'));

      const { permissions } = await inquirer.default.prompt([{
        type: 'checkbox',
        name: 'permissions',
        message: 'Select what Claude can do:',
        choices: [
          { name: 'Make git commits', value: 'commit', checked: true },
          { name: 'Push to remote', value: 'push', checked: false },
          { name: 'Create pull requests', value: 'createPR', checked: false },
          { name: 'Create GitHub issues', value: 'createIssue', checked: false },
        ],
      }]);

      config.permissions = {
        commit: permissions.includes('commit'),
        push: permissions.includes('push'),
        createPR: permissions.includes('createPR'),
        createIssue: permissions.includes('createIssue'),
      };

      console.log(chalk.dim('\nPermissions saved. You can change these in claw-workspace.json'));
    } else {
      // Default permissions for --yes flag (conservative)
      config.permissions = {
        commit: true,
        push: false,
        createPR: false,
        createIssue: false,
      };
    }

    // Save config
    await workspace.save(config);
    console.log(chalk.green(`\n✓ Workspace initialized: ${workspace.getConfigPath()}`));
    console.log(chalk.dim('Run `claw feature "description"` to start a feature.'));
  });

// claw config - Configure workspace permissions
program
  .command('config')
  .description('Configure Claude permissions and workspace settings')
  .action(async () => {
    const { Workspace } = await import('../core/workspace.js');
    const inquirer = await import('inquirer');

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    console.log(chalk.blue('\n🔒 Claude Permissions\n'));

    const currentPerms = config.permissions || {
      commit: true,
      push: false,
      createPR: false,
      createIssue: false,
    };

    const { permissions } = await inquirer.default.prompt([{
      type: 'checkbox',
      name: 'permissions',
      message: 'What should Claude be allowed to do?',
      choices: [
        { name: 'Make git commits', value: 'commit', checked: currentPerms.commit },
        { name: 'Push to remote', value: 'push', checked: currentPerms.push },
        { name: 'Create pull requests', value: 'createPR', checked: currentPerms.createPR },
        { name: 'Create GitHub issues', value: 'createIssue', checked: currentPerms.createIssue },
      ],
    }]);

    config.permissions = {
      commit: permissions.includes('commit'),
      push: permissions.includes('push'),
      createPR: permissions.includes('createPR'),
      createIssue: permissions.includes('createIssue'),
    };

    await workspace.save(config);

    console.log(chalk.green('\n✓ Permissions updated'));
    console.log(chalk.dim('\nCurrent settings:'));
    console.log(`  Commit:       ${config.permissions.commit ? chalk.green('✓') : chalk.red('✗')}`);
    console.log(`  Push:         ${config.permissions.push ? chalk.green('✓') : chalk.red('✗')}`);
    console.log(`  Create PR:    ${config.permissions.createPR ? chalk.green('✓') : chalk.red('✗')}`);
    console.log(`  Create Issue: ${config.permissions.createIssue ? chalk.green('✓') : chalk.red('✗')}`);
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

// claw run - Interactive autonomous execution
program
  .command('run [feature]')
  .description('Run pending stories autonomously (interactive mode)')
  .option('--hours <n>', 'Time budget in hours (default: unlimited)')
  .option('--stories <n>', 'Max stories to complete')
  .option('--until-blocked', 'Stop at first blocker (default: true)', true)
  .option('--model <model>', 'Claude model to use (sonnet, opus, haiku)', 'sonnet')
  .option('-y, --yes', 'Skip interactive prompts, run all pending')
  .option('--pr', 'Create PR after completion')
  .option('-i, --interactive', 'Run Claude interactively (see output, can interact)', true)
  .option('--no-interactive', 'Run in background mode (capture output)')
  .action(async (featureId, options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');
    const { SessionRunner } = await import('../core/session.js');
    const { homedir } = await import('os');
    const inquirerModule = await import('inquirer');
    const inquirerPrompt = inquirerModule.default.prompt;

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const vaultPath = (config.obsidian?.vault || '~/Documents/Obsidian').replace('~', homedir());
    const projectPath = config.obsidian?.project || `Projects/${config.name}`;
    const featureManager = new FeatureManager(vaultPath, projectPath);

    // Get all features
    const allFeatures = await featureManager.list();
    const featuresWithPending = allFeatures.filter(f =>
      f.stories.some(s => s.status === 'pending' || s.status === 'in_progress')
    );

    if (featuresWithPending.length === 0 && !featureId) {
      console.log(chalk.yellow('\n📭 No pending work found.\n'));

      // Ask if they want to add something
      const { addNew } = await inquirerPrompt([{
        type: 'input',
        name: 'addNew',
        message: 'Add a new feature or bug? (leave empty to exit):',
      }]);

      if (addNew.trim()) {
        const feature = await featureManager.create(addNew.trim());
        console.log(chalk.green(`\n✓ Created: ${feature.title}`));
        console.log(chalk.dim('Run `claw run` again to work on it.\n'));
      }
      return;
    }

    let selectedFeatures: typeof featuresWithPending = [];

    // If specific feature provided, use it
    if (featureId) {
      const feature = await featureManager.get(featureId);
      if (!feature) {
        console.log(chalk.red(`✗ Feature not found: ${featureId}`));
        process.exit(1);
      }
      selectedFeatures = [feature];
    }
    // If --yes flag, select all
    else if (options.yes) {
      selectedFeatures = featuresWithPending;
    }
    // Interactive mode
    else {
      console.log(chalk.blue('\n🤖 Claw - Autonomous Development\n'));

      // Build flat list of all stories with their feature context
      type StoryChoice = { feature: typeof featuresWithPending[0]; story: typeof featuresWithPending[0]['stories'][0] };
      let allStories: StoryChoice[] = [];

      for (const feature of allFeatures) {
        for (const story of feature.stories) {
          if (story.status === 'pending' || story.status === 'in_progress') {
            allStories.push({ feature, story });
          }
        }
      }

      // Main interaction loop - list-based navigation
      let continueLoop = true;
      let selectedForRun: StoryChoice[] = [];

      while (continueLoop) {
        // Show current selection status
        if (selectedForRun.length > 0) {
          console.log(chalk.green(`\n✓ ${selectedForRun.length} story(ies) selected for run`));
        }

        // Build list of stories for browsing
        const storyChoices = allStories.map((item, idx) => {
          const statusIcon = item.story.status === 'in_progress' ? '🔄' : '⏳';
          const isSelected = selectedForRun.some(s => s.story.id === item.story.id && s.feature.id === item.feature.id);
          const selectedMark = isSelected ? chalk.green('✓ ') : '  ';
          const featureLabel = chalk.dim(`[${item.feature.title}]`);
          // Truncate long titles
          const title = item.story.title.length > 60
            ? item.story.title.substring(0, 57) + '...'
            : item.story.title;
          return {
            name: `${selectedMark}${statusIcon} ${title} ${featureLabel}`,
            value: idx,
          };
        });

        // Add action options
        const allChoices: any[] = [
          ...storyChoices,
          new inquirerModule.default.Separator('─────────────────────────────────'),
          { name: chalk.green('➕ Add new bug/feature'), value: 'add' },
          ...(selectedForRun.length > 0 ? [
            { name: chalk.blue(`▶️  Run ${selectedForRun.length} selected`), value: 'run_selected' },
            { name: chalk.dim('↩️  Clear selection'), value: 'clear' },
          ] : []),
          { name: chalk.blue('▶️  Run all pending'), value: 'run_all' },
        ];

        const { choice } = await inquirerPrompt([{
          type: 'list',
          name: 'choice',
          message: 'Browse stories (select to see options):',
          choices: allChoices,
          pageSize: 20,
        }]);

        // Handle global actions
        if (choice === 'add') {
          const { newWork } = await inquirerPrompt([{
            type: 'input',
            name: 'newWork',
            message: 'Describe the bug or feature:',
          }]);

          if (newWork.trim()) {
            const isBug = /bug|fix|broken|error|crash|issue/i.test(newWork);

            if (isBug) {
              let bugsFeature = await featureManager.get('bugs');
              if (!bugsFeature) {
                bugsFeature = await featureManager.create('Bug Tracking', { id: 'bugs' });
              }
              const storyId = String(bugsFeature.stories.length + 1);
              const newStory = {
                id: storyId,
                title: newWork.trim(),
                status: 'pending' as const,
                scope: [newWork.trim()],
                repos: [],
              };
              bugsFeature.stories.push(newStory);
              await featureManager.update(bugsFeature);
              allStories.push({ feature: bugsFeature, story: newStory });
              console.log(chalk.green(`  ✓ Added bug: "${newWork.trim()}"`));
            } else {
              const newFeature = await featureManager.create(newWork.trim());
              allStories.push({ feature: newFeature, story: newFeature.stories[0] });
              console.log(chalk.green(`  ✓ Added feature: "${newWork.trim()}"`));
            }
          }
          continue;
        }

        if (choice === 'clear') {
          selectedForRun = [];
          console.log(chalk.dim('Selection cleared.'));
          continue;
        }

        if (choice === 'run_all') {
          selectedForRun = [...allStories];
          // Fall through to run
        }

        if (choice === 'run_selected' || choice === 'run_all') {
          // Group selected stories by feature
          const featureMap = new Map<string, typeof featuresWithPending[0]>();
          for (const item of selectedForRun) {
            if (!featureMap.has(item.feature.id)) {
              const featureCopy = { ...item.feature, stories: [] as typeof item.feature.stories };
              featureMap.set(item.feature.id, featureCopy);
            }
            featureMap.get(item.feature.id)!.stories.push(item.story);
          }
          selectedFeatures = Array.from(featureMap.values());

          console.log(chalk.dim('\n─────────────────────────────────'));
          console.log(chalk.bold('Session Summary:'));
          console.log(`  Stories:  ${selectedForRun.length}`);
          console.log(`  Mode:     Run until blocked`);
          console.log(chalk.dim('─────────────────────────────────\n'));

          const { confirm } = await inquirerPrompt([{
            type: 'confirm',
            name: 'confirm',
            message: 'Start working?',
            default: true,
          }]);

          if (confirm) {
            continueLoop = false;
          }
          continue;
        }

        // User selected a specific story - show action menu
        if (typeof choice === 'number') {
          const item = allStories[choice];

          // Show story details first
          console.log(chalk.blue('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
          console.log(chalk.bold(`📋 ${item.story.title}`));
          console.log(chalk.blue('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
          console.log(`${chalk.dim('Feature:')} ${item.feature.title}`);
          console.log(`${chalk.dim('Status:')}  ${item.story.status}`);
          console.log(`${chalk.dim('ID:')}      ${item.feature.id}/${item.story.id}`);
          if (item.story.branch) {
            console.log(`${chalk.dim('Branch:')}  ${item.story.branch}`);
          }
          console.log(chalk.dim('\nScope:'));
          item.story.scope.forEach(s => console.log(`  - ${s}`));
          if (item.story.blockedBy && item.story.blockedBy.length > 0) {
            console.log(chalk.dim('\nBlocked by:'));
            item.story.blockedBy.forEach(b => console.log(`  - ${b}`));
          }
          console.log('');

          // Show action menu for this story
          const isAlreadySelected = selectedForRun.some(s => s.story.id === item.story.id && s.feature.id === item.feature.id);

          const { action } = await inquirerPrompt([{
            type: 'list',
            name: 'action',
            message: 'What do you want to do?',
            choices: [
              isAlreadySelected
                ? { name: '➖ Remove from run queue', value: 'deselect' }
                : { name: '➕ Add to run queue', value: 'select' },
              { name: '▶️  Run this story now', value: 'run_now' },
              { name: '📂 Open in Obsidian', value: 'open_obsidian' },
              { name: '✏️  Edit story', value: 'edit' },
              { name: '🗑️  Remove story', value: 'remove' },
              { name: '↩️  Back to list', value: 'back' },
            ],
          }]);

          if (action === 'back') {
            continue;
          }

          if (action === 'select') {
            selectedForRun.push(item);
            console.log(chalk.green(`  ✓ Added to run queue`));
            continue;
          }

          if (action === 'deselect') {
            selectedForRun = selectedForRun.filter(s => !(s.story.id === item.story.id && s.feature.id === item.feature.id));
            console.log(chalk.dim('  Removed from run queue'));
            continue;
          }

          if (action === 'run_now') {
            selectedForRun = [item];
            const featureCopy = { ...item.feature, stories: [item.story] };
            selectedFeatures = [featureCopy];
            continueLoop = false;
            continue;
          }

          if (action === 'open_obsidian') {
            const { exec } = await import('child_process');
            const notePath = `${vaultPath}/${projectPath}/features/${item.feature.id}/_overview.md`;
            // Open in Obsidian using obsidian:// URI
            const obsidianUri = `obsidian://open?vault=${encodeURIComponent(vaultPath.split('/').pop() || 'Obsidian')}&file=${encodeURIComponent(`${projectPath}/features/${item.feature.id}/_overview`)}`;
            exec(`open "${obsidianUri}"`, (err) => {
              if (err) {
                console.log(chalk.yellow(`  Could not open Obsidian. File path: ${notePath}`));
              } else {
                console.log(chalk.green(`  ✓ Opened in Obsidian`));
              }
            });
            continue;
          }

          if (action === 'edit') {
            console.log(chalk.dim(`\nEditing: ${item.story.title}\n`));

            const { newTitle } = await inquirerPrompt([{
              type: 'input',
              name: 'newTitle',
              message: 'New title (leave empty to keep):',
              default: item.story.title,
            }]);

            const { newScope } = await inquirerPrompt([{
              type: 'input',
              name: 'newScope',
              message: 'New scope (comma-separated, leave empty to keep):',
              default: item.story.scope.join(', '),
            }]);

            // Update the story
            item.story.title = newTitle || item.story.title;
            item.story.scope = newScope ? newScope.split(',').map((s: string) => s.trim()) : item.story.scope;

            await featureManager.updateStory(item.feature.id, item.story.id, {
              title: item.story.title,
              scope: item.story.scope,
            });
            console.log(chalk.green('  ✓ Story updated'));
            continue;
          }

          if (action === 'remove') {
            const { confirmRemove } = await inquirerPrompt([{
              type: 'confirm',
              name: 'confirmRemove',
              message: 'Remove this story? This cannot be undone.',
              default: false,
            }]);

            if (confirmRemove) {
              const feature = await featureManager.get(item.feature.id);
              if (feature) {
                feature.stories = feature.stories.filter(s => s.id !== item.story.id);
                await featureManager.update(feature);
              }
              allStories = allStories.filter(s => !(s.story.id === item.story.id && s.feature.id === item.feature.id));
              selectedForRun = selectedForRun.filter(s => !(s.story.id === item.story.id && s.feature.id === item.feature.id));
              console.log(chalk.green('  ✓ Story removed'));
            }
            continue;
          }
        }
      }
    }

    // Run session for each selected feature
    console.log(chalk.blue('\n🚀 Starting autonomous session...\n'));

    const runner = new SessionRunner(process.cwd(), vaultPath, projectPath);

    for (const feature of selectedFeatures) {
      console.log(chalk.bold(`\n📋 Working on: ${feature.title}`));

      const result = await runner.run(feature, {
        maxHours: options.hours ? parseFloat(options.hours) : undefined,
        maxStories: options.stories ? parseInt(options.stories, 10) : undefined,
        stopOnBlocker: options.untilBlocked,
        model: options.model as 'sonnet' | 'opus' | 'haiku',
        dangerouslySkipPermissions: !options.interactive, // Only skip if non-interactive
        createPROnComplete: options.pr,
        interactive: options.interactive,
      });

      if (!result.success && result.error?.includes('blocked')) {
        console.log(chalk.yellow(`\n⚠️  Blocked: ${result.error}`));
        console.log(chalk.dim('Moving to next feature...\n'));
        continue;
      }

      if (!result.success) {
        console.log(chalk.yellow(`\nSession ended: ${result.error || 'incomplete'}`));
        break;
      }
    }

    console.log(chalk.green('\n✅ Session complete!\n'));
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
  .option('-i, --interactive', 'Run Claude interactively (see output, can interact)', true)
  .option('--no-interactive', 'Run in background mode (capture output)')
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

    // In interactive mode, no spinner - Claude output goes directly to terminal
    const spinner = options.interactive ? null : ora('Scanning codebase...').start();

    const results = await engine.runDiscovery({
      mode: options.mode,
      focus: options.focus,
      repos: config.repos,
      interactive: options.interactive,
    });

    if (spinner) spinner.stop();

    // In interactive mode, user already saw all output
    if (options.interactive) {
      console.log(chalk.green('\n✓ Discovery complete!'));
      console.log(chalk.dim('Review the findings above and run `claw feature` to create stories.'));
      return;
    }

    // Non-interactive: display parsed results
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
      console.log(chalk.dim('Tip: Run `claw brainstorm` to get ideas for new features and improvements.'));
    } else {
      console.log(chalk.dim(`\nTotal: ${totalFindings} findings`));
      console.log(chalk.dim('Run `claw feature` to create stories from these findings.'));
    }
  });

// claw brainstorm - Get ideas for new features and improvements
program
  .command('brainstorm')
  .description('Brainstorm ideas for new features, improvements, and optimizations')
  .option('-f, --focus <area>', 'Focus on specific area (e.g., ux, performance, features)')
  .option('--model <model>', 'Claude model to use (sonnet, opus)', 'sonnet')
  .action(async (options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { ClaudeClient } = await import('../integrations/claude.js');

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const claude = new ClaudeClient(process.cwd());

    // Build the brainstorming prompt
    let prompt = `You are analyzing a codebase to brainstorm ideas for improvements and new features.

## Project Context
Name: ${config.name}
Repos: ${config.repos.map(r => `${r.name} (${r.type})`).join(', ')}

## Your Task

Explore this codebase and brainstorm ideas in these categories:

1. **New Features** - What features could be added to enhance this project?
2. **UX Improvements** - How could the user experience be improved?
3. **Performance** - What could be optimized for speed or efficiency?
4. **Developer Experience** - What would make this codebase easier to work with?
5. **Architecture** - Are there structural improvements that would help?

For each idea, explain:
- What it would do
- Why it would be valuable
- How complex it would be to implement (small/medium/large)

Be creative but practical. Focus on ideas that would genuinely improve the project.`;

    if (options.focus) {
      prompt += `\n\n**Focus Area:** ${options.focus}\nPrioritize ideas related to ${options.focus}.`;
    }

    prompt += '\n\nStart by exploring the codebase to understand what it does, then share your brainstorming ideas.';

    console.log(chalk.blue('\n💡 Starting brainstorm session...\n'));
    console.log(chalk.dim('Claude will explore your codebase and suggest ideas.\n'));

    try {
      // Run interactively so user can discuss ideas with Claude
      await claude.runInteractive(prompt, {
        model: options.model as 'sonnet' | 'opus',
      });

      console.log(chalk.green('\n✓ Brainstorm session complete!'));
      console.log(chalk.dim('Run `claw feature "<idea>"` to create a story from an idea.'));
    } catch (error) {
      console.log(chalk.red(`\n✗ Error: ${error instanceof Error ? error.message : String(error)}`));
      process.exit(1);
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

// claw migrate - Convert existing markdown files to claw features
program
  .command('migrate [path]')
  .description('Migrate existing markdown files to claw feature format')
  .option('--dry-run', 'Preview changes without writing files')
  .option('--auto', 'Skip interactive prompts, convert all convertible files')
  .action(async (pathArg, options) => {
    const inquirerModule = await import('inquirer');
    const inquirerPrompt = inquirerModule.default.prompt;
    const { Workspace } = await import('../core/workspace.js');
    const {
      scanForConvertible,
      isConvertible,
      parseMarkdownToStories,
      convertFile,
    } = await import('../core/converter.js');
    const { readFile } = await import('fs/promises');
    const { join, basename, dirname } = await import('path');
    const { homedir } = await import('os');

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const vaultPath = (config.obsidian?.vault || '~/Documents/Obsidian').replace('~', homedir());
    const projectPath = config.obsidian?.project || `Projects/${config.name}`;
    const obsidianProjectDir = join(vaultPath, projectPath);
    const featuresDir = join(obsidianProjectDir, 'features');

    console.log(chalk.blue('🔄 Scanning for convertible files...\n'));

    // Determine scan path
    const scanPath = pathArg
      ? (pathArg.startsWith('/') ? pathArg : join(obsidianProjectDir, pathArg))
      : obsidianProjectDir;

    const convertibleFiles = await scanForConvertible(scanPath);

    if (convertibleFiles.length === 0) {
      console.log(chalk.yellow('No convertible files found.'));
      console.log(chalk.dim('Convertible files contain task lists (- [ ]) or priority tables.'));
      process.exit(0);
    }

    console.log(chalk.green(`Found ${convertibleFiles.length} convertible file(s):\n`));

    const conversions: { file: string; action: string; featureId?: string }[] = [];

    for (const filePath of convertibleFiles) {
      const content = await readFile(filePath, 'utf-8');
      const filename = basename(filePath);
      const relativePath = filePath.replace(obsidianProjectDir + '/', '');

      // Parse to show preview
      const { title, stories, completedItems, deferredItems } = parseMarkdownToStories(content, filename);
      const pendingCount = stories.filter(s => s.status === 'pending').length;

      console.log(chalk.bold(`📄 ${relativePath}`));
      console.log(chalk.dim(`   Title: ${title}`));
      console.log(chalk.dim(`   Pending: ${pendingCount} | Completed: ${completedItems.length} | Deferred: ${deferredItems.length}`));

      if (pendingCount > 0) {
        console.log(chalk.cyan('   Stories to create:'));
        stories.filter(s => s.status === 'pending').slice(0, 5).forEach(s => {
          console.log(chalk.dim(`     - ${s.title}`));
        });
        if (pendingCount > 5) {
          console.log(chalk.dim(`     ... and ${pendingCount - 5} more`));
        }
      }

      if (options.auto) {
        // Auto mode - convert all
        conversions.push({ file: filePath, action: 'convert' });
        console.log(chalk.green('   → Will convert to feature\n'));
      } else {
        // Interactive mode
        const { action } = await inquirerPrompt([{
          type: 'list',
          name: 'action',
          message: 'What should we do with this file?',
          choices: [
            { name: '✓ Convert to claw feature', value: 'convert' },
            { name: '📁 Move to specific folder (documentation)', value: 'move' },
            { name: '⏭️  Skip (leave as-is)', value: 'skip' },
          ],
        }]);

        if (action === 'convert') {
          const { featureId } = await inquirerPrompt([{
            type: 'input',
            name: 'featureId',
            message: 'Feature ID (folder name):',
            default: basename(filename, '.md').toLowerCase().replace(/[^a-z0-9]+/g, '-'),
          }]);
          conversions.push({ file: filePath, action: 'convert', featureId });
        } else if (action === 'move') {
          const { folder } = await inquirerPrompt([{
            type: 'input',
            name: 'folder',
            message: 'Destination folder (relative to project):',
            default: 'docs',
          }]);
          conversions.push({ file: filePath, action: 'move', featureId: folder });
        } else {
          conversions.push({ file: filePath, action: 'skip' });
        }
        console.log('');
      }
    }

    // Summary
    const toConvert = conversions.filter(c => c.action === 'convert');
    const toMove = conversions.filter(c => c.action === 'move');
    const toSkip = conversions.filter(c => c.action === 'skip');

    console.log(chalk.blue('\n📋 Migration Summary'));
    console.log(`   Convert to features: ${toConvert.length}`);
    console.log(`   Move to folders: ${toMove.length}`);
    console.log(`   Skip: ${toSkip.length}`);

    if (options.dryRun) {
      console.log(chalk.yellow('\n⚠️  Dry run - no files were modified.'));
      console.log(chalk.dim('Remove --dry-run to apply changes.'));
      process.exit(0);
    }

    if (toConvert.length === 0 && toMove.length === 0) {
      console.log(chalk.dim('\nNothing to do.'));
      process.exit(0);
    }

    // Execute conversions
    console.log(chalk.blue('\n🔄 Applying changes...\n'));

    for (const conv of toConvert) {
      const result = await convertFile(conv.file, featuresDir, {
        archive: true,
        featureId: conv.featureId,
      });

      if (result.success) {
        console.log(chalk.green(`✓ Converted: ${basename(conv.file)} → features/${result.featureId}/`));
      } else {
        console.log(chalk.red(`✗ Failed: ${basename(conv.file)} - ${result.error}`));
      }
    }

    for (const conv of toMove) {
      try {
        const { rename, mkdir } = await import('fs/promises');
        const destDir = join(obsidianProjectDir, conv.featureId || 'docs');
        const { existsSync } = await import('fs');
        if (!existsSync(destDir)) {
          await mkdir(destDir, { recursive: true });
        }
        await rename(conv.file, join(destDir, basename(conv.file)));
        console.log(chalk.green(`✓ Moved: ${basename(conv.file)} → ${conv.featureId}/`));
      } catch (error) {
        console.log(chalk.red(`✗ Failed to move: ${basename(conv.file)}`));
      }
    }

    // Final instructions
    console.log(chalk.green('\n✅ Migration complete!\n'));
    console.log(chalk.bold('Next steps:'));
    console.log(chalk.dim('  1. Review converted features:'));
    console.log(`     ${chalk.cyan('claw list')}`);
    console.log(chalk.dim('  2. Run a feature:'));
    console.log(`     ${chalk.cyan('claw run <feature-id> --hours 4')}`);
    console.log(chalk.dim('  3. Check feature status:'));
    console.log(`     ${chalk.cyan('claw status <feature-id>')}`);
  });

// claw bug - Quick capture a bug to Obsidian
program
  .command('bug <description>')
  .description('Quick capture a bug to the bugs feature in Obsidian')
  .option('-p, --priority <level>', 'Priority: P0, P1, P2, P3', 'P2')
  .option('-f, --feature <id>', 'Add to specific feature instead of bugs')
  .option('-i, --image <path>', 'Attach a screenshot or image')
  .option('--clipboard', 'Attach image from clipboard (macOS)')
  .action(async (description, options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');
    const { homedir } = await import('os');
    const { copyFile, mkdir } = await import('fs/promises');
    const { existsSync } = await import('fs');
    const { join, basename, extname } = await import('path');
    const { exec } = await import('child_process');
    const { promisify } = await import('util');
    const execAsync = promisify(exec);

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const vaultPath = (config.obsidian?.vault || '~/Documents/Obsidian').replace('~', homedir());
    const projectPath = config.obsidian?.project || `Projects/${config.name}`;
    const featureManager = new FeatureManager(vaultPath, projectPath);

    // Use specified feature or default to 'bugs'
    const featureId = options.feature || 'bugs';

    // Check if feature exists, create if not
    let feature = await featureManager.get(featureId);

    if (!feature) {
      if (featureId === 'bugs') {
        // Auto-create bugs feature
        console.log(chalk.dim('Creating bugs feature...'));
        feature = await featureManager.create('Bug Tracking', { id: 'bugs' });
      } else {
        console.log(chalk.red(`✗ Feature not found: ${featureId}`));
        console.log(chalk.dim('Use --feature bugs or create the feature first.'));
        process.exit(1);
      }
    }

    // Handle image attachment
    let imageRef = '';
    const attachmentsDir = join(vaultPath, projectPath, 'attachments');

    if (options.image || options.clipboard) {
      // Ensure attachments directory exists
      if (!existsSync(attachmentsDir)) {
        await mkdir(attachmentsDir, { recursive: true });
      }

      const timestamp = Date.now();
      let imagePath = options.image;
      let imageName = '';

      if (options.clipboard) {
        // Save clipboard image using pngpaste (macOS)
        imageName = `bug-${timestamp}.png`;
        const destPath = join(attachmentsDir, imageName);
        try {
          await execAsync(`pngpaste "${destPath}"`);
          console.log(chalk.green('  ✓ Captured image from clipboard'));
        } catch (err) {
          console.log(chalk.yellow('  ⚠ Could not capture clipboard. Install pngpaste: brew install pngpaste'));
          // Continue without image
        }
      } else if (imagePath) {
        // Copy provided image
        if (!existsSync(imagePath)) {
          console.log(chalk.yellow(`  ⚠ Image not found: ${imagePath}`));
        } else {
          const ext = extname(imagePath) || '.png';
          imageName = `bug-${timestamp}${ext}`;
          const destPath = join(attachmentsDir, imageName);
          await copyFile(imagePath, destPath);
          console.log(chalk.green(`  ✓ Attached image: ${basename(imagePath)}`));
        }
      }

      if (imageName) {
        // Create Obsidian-style image reference
        imageRef = `![[attachments/${imageName}]]`;
      }
    }

    // Add bug as a story
    const storyId = String(feature.stories.length + 1);
    const scope = [description];
    if (imageRef) {
      scope.push(`Screenshot: ${imageRef}`);
    }

    const story = {
      id: storyId,
      title: `[${options.priority}] ${description}`,
      status: 'pending' as const,
      scope,
      repos: [],
    };

    feature.stories.push(story);
    await featureManager.update(feature);

    console.log(chalk.green(`✓ Bug captured: ${description}`));
    console.log(chalk.dim(`  Feature: ${featureId}`));
    console.log(chalk.dim(`  Story: #${storyId}`));
    console.log(chalk.dim(`  Priority: ${options.priority}`));
    if (imageRef) {
      console.log(chalk.dim(`  Image: ${imageRef}`));
    }
    console.log('');
    console.log(chalk.dim(`Run \`claw run ${featureId}\` to work on bugs.`));
  });

// claw issue - Export a story to GitHub Issue (for team visibility)
program
  .command('issue <feature> [story]')
  .description('Export a story to GitHub Issue (optional, for team visibility)')
  .option('-l, --labels <labels>', 'Comma-separated labels', 'bug,claude-ready')
  .action(async (featureId, storyId, options) => {
    const { Workspace } = await import('../core/workspace.js');
    const { FeatureManager } = await import('../core/feature.js');
    const { GitHubClient } = await import('../integrations/github.js');
    const { homedir } = await import('os');
    const inquirerModule = await import('inquirer');
    const inquirerPrompt = inquirerModule.default.prompt;

    const workspace = new Workspace(process.cwd());
    const config = await workspace.load();

    if (!config) {
      console.log(chalk.red('✗ Workspace not initialized. Run `claw init` first.'));
      process.exit(1);
    }

    const vaultPath = (config.obsidian?.vault || '~/Documents/Obsidian').replace('~', homedir());
    const projectPath = config.obsidian?.project || `Projects/${config.name}`;
    const featureManager = new FeatureManager(vaultPath, projectPath);

    // Get feature
    const feature = await featureManager.get(featureId);
    if (!feature) {
      console.log(chalk.red(`✗ Feature not found: ${featureId}`));
      process.exit(1);
    }

    // Get story (or let user pick)
    let story;
    if (storyId) {
      story = feature.stories.find(s => s.id === storyId);
      if (!story) {
        console.log(chalk.red(`✗ Story not found: ${storyId}`));
        process.exit(1);
      }
    } else {
      // Let user pick a story
      const pendingStories = feature.stories.filter(s => s.status === 'pending');
      if (pendingStories.length === 0) {
        console.log(chalk.yellow('No pending stories to export.'));
        process.exit(0);
      }

      const { selectedStory } = await inquirerPrompt([{
        type: 'list',
        name: 'selectedStory',
        message: 'Select story to export to GitHub:',
        choices: pendingStories.map(s => ({
          name: `#${s.id} - ${s.title}`,
          value: s.id,
        })),
      }]);
      story = feature.stories.find(s => s.id === selectedStory)!;
    }

    // Check GitHub auth
    const github = new GitHubClient(process.cwd());
    const isAuth = await github.isAuthenticated();
    if (!isAuth) {
      console.log(chalk.red('✗ Not authenticated with GitHub. Run `gh auth login`.'));
      process.exit(1);
    }

    // Create GitHub issue
    console.log(chalk.dim(`\nExporting to GitHub Issue...`));

    const labels = options.labels.split(',').map((l: string) => l.trim());
    const issueBody = `## Description

${story.scope || story.title}

## Source

- **Feature:** ${feature.title} (\`${feature.id}\`)
- **Story:** #${story.id}
- **Obsidian:** ${projectPath}/features/${feature.id}/_overview.md

---

*Exported from claw*`;

    try {
      const issue = await github.createIssue(story.title, issueBody, labels);
      console.log(chalk.green(`✓ GitHub Issue created: #${issue.number}`));
      console.log(chalk.dim(`  https://github.com/.../${issue.number}`));
      console.log('');
      console.log(chalk.dim('Note: The story remains in Obsidian as source of truth.'));
      console.log(chalk.dim('The GitHub issue is for team visibility only.'));
    } catch (error) {
      console.log(chalk.red(`✗ Failed to create issue: ${error instanceof Error ? error.message : error}`));
      process.exit(1);
    }
  });

// Parse and run
program.parse();
