#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import { readFileSync, existsSync, mkdirSync, writeFileSync, readdirSync, statSync, copyFileSync, unlinkSync } from 'fs';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join, basename } from 'path';
import { homedir } from 'os';

// Read package.json for version
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const packageJson = JSON.parse(readFileSync(join(__dirname, '../../package.json'), 'utf-8'));

const program = new Command();

program
  .name('claw')
  .description('Claw v3 - Minimal bootstrapper for Claude Code skills')
  .version(packageJson.version, '-v, --version', 'Display version number');

// Types
interface AppConfig {
  path: string;
  devCommand: string;
  devUrl: string;
  e2eCommand?: string;
}

interface ClawConfig {
  mode: 'solo' | 'team';
  workMode: 'careful' | 'fast';
  source: {
    obsidian: boolean;
    github: boolean;
  };
  create: {
    obsidian: boolean;
    github: boolean;
  };
  obsidian: {
    vault: string;
    project: string;
  };
  github?: {
    labels: {
      bug: string;
      feature: string;
      improvement: string;
    };
  };
  autoClose: 'ask' | 'never' | 'always';
  apps: Record<string, AppConfig>;
  testing: {
    tdd: boolean;
    runner: string;
    e2e: {
      tool: string;
      browser: string;
      headed: boolean;
      screenshotOnFail: boolean;
    };
  };
}

// Detect repo type
function detectRepoType(): 'monorepo' | 'multirepo' | 'none' {
  const cwd = process.cwd();

  // Check if current dir is a git repo
  if (existsSync(join(cwd, '.git'))) {
    return 'monorepo';
  }

  // Check if subdirectories have .git
  const entries = readdirSync(cwd);
  const hasChildRepos = entries.some(entry => {
    const entryPath = join(cwd, entry);
    return statSync(entryPath).isDirectory() && existsSync(join(entryPath, '.git'));
  });

  if (hasChildRepos) {
    return 'multirepo';
  }

  return 'none';
}

// Get child repos for multi-repo workspace
function getChildRepos(): string[] {
  const cwd = process.cwd();
  const entries = readdirSync(cwd);

  return entries.filter(entry => {
    const entryPath = join(cwd, entry);
    return statSync(entryPath).isDirectory() && existsSync(join(entryPath, '.git'));
  });
}

// Setup global gitignore
function setupGlobalGitignore(): void {
  const globalGitignore = join(homedir(), '.gitignore_global');

  // Create if doesn't exist
  if (!existsSync(globalGitignore)) {
    writeFileSync(globalGitignore, '');
  }

  // Configure git to use it
  try {
    execSync(`git config --global core.excludesfile "${globalGitignore}"`, { stdio: 'pipe' });
  } catch {
    // Ignore errors
  }

  // Read current content
  let content = readFileSync(globalGitignore, 'utf-8');

  // Add patterns if not present
  const patterns = ['.claude/', '.claw-session.md', '.claw/'];
  for (const pattern of patterns) {
    const regex = new RegExp(`^${pattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'm');
    if (!regex.test(content)) {
      content += `${content.endsWith('\n') ? '' : '\n'}${pattern}\n`;
    }
  }

  writeFileSync(globalGitignore, content);
}

// Copy skills to target directory
function copySkills(targetDir: string): number {
  const skillsSource = join(__dirname, '../../templates/skills');
  const skillsTarget = join(targetDir, '.claude/skills/claw');

  // Create target directory (skills must be in a subdirectory)
  mkdirSync(skillsTarget, { recursive: true });

  // Clean up old v2 skill files that might be in wrong locations
  const oldSkillsDir = join(targetDir, '.claude/skills');
  const oldSkills = ['bug.md', 'feature.md', 'improvement.md', 'brainstorm.md', 'run.md', 'report-bug.md', 'new-feature.md', 'new-improvement.md', 'SKILL.md'];
  for (const oldSkill of oldSkills) {
    const oldPath = join(oldSkillsDir, oldSkill);
    if (existsSync(oldPath)) {
      unlinkSync(oldPath);
    }
  }

  // Check if source exists
  if (!existsSync(skillsSource)) {
    // Create default skills if templates don't exist yet
    const defaultSkills = {
      'run.md': `# /run

Select items from Obsidian (bugs, features, improvements) and execute them autonomously.

## Flow

1. Read \`.claw/config.json\` for configuration
2. List items from configured sources (Obsidian and/or GitHub)
3. Let user select items to work on
4. Create \`.claw-session.md\` with selected items
5. Work through each item, updating progress
6. On completion, ask about closing issues (if configured)

## Session Recovery

**CRITICAL: After context compaction, read \`.claw-session.md\` to recover state.**

Check progress markers and continue from where you left off.

## Session File Format

\`\`\`markdown
# Session: <name>
Started: <timestamp>

## Items

### 1. <title>
- [x] Understood
- [ ] Tests written
- [ ] Implementation
- [ ] Verified

### 2. <title>
...
\`\`\`
`,
      'report-bug.md': `# /report-bug

Create a bug report in Obsidian (and optionally GitHub in team mode).

## Flow

1. Ask user for bug description
2. Ask for priority (P0-P3)
3. Ask if screenshot needed
4. Create bug note in Obsidian: \`bugs/<slug>.md\`
5. If team mode: also create GitHub issue

## Bug Note Format

\`\`\`markdown
# Bug: <title>

**Priority:** P2
**Status:** pending
**Created:** <date>

## Description

<description>

## Screenshots

<if any>

## Steps to Reproduce

1. ...

## Expected vs Actual

...
\`\`\`
`,
      'new-feature.md': `# /new-feature

Create a feature request in Obsidian (and optionally GitHub in team mode).

## Flow

1. Ask user for feature description
2. Ask clarifying questions about scope
3. Ask if E2E tests needed
4. Create feature note in Obsidian: \`features/<slug>.md\`
5. If team mode: also create GitHub issue

## Feature Note Format

\`\`\`markdown
# Feature: <title>

**Status:** pending
**Created:** <date>
**E2E Required:** <yes/no>

## Description

<description>

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Notes

...
\`\`\`
`,
      'new-improvement.md': `# /new-improvement

Create an improvement (refactor, tech-debt, performance, coverage) in Obsidian.

## Scope

- **Refactors** - restructure code, no behavior change
- **Tech-debt** - clean up TODOs, hacks, outdated patterns
- **Performance** - optimizations, speed improvements
- **Code coverage** - add missing tests

## Flow

1. Ask user for improvement description
2. Ask for category (refactor/tech-debt/performance/coverage)
3. Create improvement note in Obsidian: \`improvements/<slug>.md\`
4. If team mode: also create GitHub issue

## Improvement Note Format

\`\`\`markdown
# Improvement: <title>

**Category:** <category>
**Status:** pending
**Created:** <date>

## Description

<description>

## Approach

...
\`\`\`
`,
    };

    for (const [name, content] of Object.entries(defaultSkills)) {
      writeFileSync(join(skillsTarget, name), content);
    }

    return Object.keys(defaultSkills).length;
  }

  // Copy from templates
  const files = readdirSync(skillsSource);
  let count = 0;

  for (const file of files) {
    if (file.endsWith('.md')) {
      copyFileSync(join(skillsSource, file), join(skillsTarget, file));
      count++;
    }
  }

  return count;
}

// Create config file
function createConfig(targetDir: string, config: ClawConfig): void {
  const configDir = join(targetDir, '.claw');
  mkdirSync(configDir, { recursive: true });
  writeFileSync(join(configDir, 'config.json'), JSON.stringify(config, null, 2));
}

// Create CLAUDE.md if doesn't exist
function createClaudeMd(targetDir: string, projectName: string): boolean {
  const claudeMdPath = join(targetDir, 'CLAUDE.md');

  if (existsSync(claudeMdPath)) {
    return false;
  }

  const content = `# ${projectName}

## Active Session

**On session start or after compaction:**

1. Read \`.claw-session.md\` if it exists
2. Check progress markers
3. Continue from where you left off

If no session file exists, no active work.

## Available Commands

- \`/run\` - Start a work session
- \`/report-bug\` - Report a bug
- \`/new-feature\` - Propose a feature
- \`/new-improvement\` - Suggest an improvement

## Configuration

See \`.claw/config.json\` for project settings.
`;

  writeFileSync(claudeMdPath, content);
  return true;
}

// Load existing config if present
function loadExistingConfig(targetDir: string): Partial<ClawConfig> | null {
  const configPath = join(targetDir, '.claw/config.json');
  if (existsSync(configPath)) {
    try {
      return JSON.parse(readFileSync(configPath, 'utf-8'));
    } catch {
      return null;
    }
  }
  return null;
}

// claw init - The only command
program
  .command('init')
  .description('Initialize claw in this project')
  .option('-y, --yes', 'Accept defaults without prompts')
  .option('-f, --force', 'Re-prompt for all options (ignore existing config)')
  .action(async (options) => {
    const inquirerModule = await import('inquirer');
    const inquirerPrompt = inquirerModule.default.prompt;

    console.log(chalk.blue(`\nclaw v${packageJson.version}\n`));

    // Detect repo type
    const repoType = detectRepoType();

    if (repoType === 'none') {
      console.log(chalk.red('No git repositories found.'));
      console.log(chalk.dim('Run this in a git repo or a directory containing git repos.'));
      process.exit(1);
    }

    const projectName = basename(process.cwd());
    console.log(`Detected: ${repoType === 'monorepo' ? 'monorepo' : 'multi-repo workspace'} (${projectName})`);

    // Check for existing config
    const existingConfig = options.force ? null : loadExistingConfig(process.cwd());
    if (existingConfig && !options.force) {
      console.log(chalk.dim('Found existing .claw/config.json - using as defaults'));
      console.log(chalk.dim('Use --force to re-prompt for all options\n'));
    }

    // Setup global gitignore
    setupGlobalGitignore();
    console.log(chalk.green('✓ Global gitignore configured'));

    // Get configuration
    let config: ClawConfig;

    // Default config structure
    const defaultConfig: ClawConfig = {
      mode: 'solo',
      workMode: 'careful',
      source: { obsidian: true, github: false },
      create: { obsidian: true, github: false },
      obsidian: {
        vault: '~/Documents/Obsidian',
        project: `Projects/${projectName}`,
      },
      autoClose: 'ask',
      apps: {
        main: {
          path: '.',
          devCommand: 'npm run dev',
          devUrl: 'http://localhost:3000',
        },
      },
      testing: {
        tdd: true,
        runner: 'jest',
        e2e: {
          tool: 'playwright',
          browser: 'chromium',
          headed: false,
          screenshotOnFail: true,
        },
      },
    };

    if (options.yes) {
      // Use existing config merged with defaults, or just defaults
      config = existingConfig
        ? { ...defaultConfig, ...existingConfig } as ClawConfig
        : defaultConfig;
    } else {
      // Interactive prompts - use existing values as defaults
      const ec = existingConfig || {};

      // Only prompt for fields that don't exist or if --force
      let mode = ec.mode;
      let workMode = ec.workMode;
      let vaultPath = ec.obsidian?.vault;
      let projectFolder = ec.obsidian?.project;
      let apps = ec.apps;
      let e2eConfig = ec.testing?.e2e;

      // Core settings - prompt if missing
      if (!mode) {
        const result = await inquirerPrompt([{
          type: 'list',
          name: 'mode',
          message: 'Mode:',
          choices: [
            { name: 'Solo (Obsidian only, stealth)', value: 'solo' },
            { name: 'Team (GitHub + Obsidian synced)', value: 'team' },
          ],
        }]);
        mode = result.mode;
      } else {
        console.log(chalk.dim(`Mode: ${mode} (from existing config)`));
      }

      if (!workMode) {
        const result = await inquirerPrompt([{
          type: 'list',
          name: 'workMode',
          message: 'Work style:',
          choices: [
            { name: 'Careful (show options, small chunks, diff before commit)', value: 'careful' },
            { name: 'Fast (trust approach, show result after)', value: 'fast' },
          ],
        }]);
        workMode = result.workMode;
      } else {
        console.log(chalk.dim(`Work style: ${workMode} (from existing config)`));
      }

      if (!vaultPath) {
        const result = await inquirerPrompt([{
          type: 'input',
          name: 'vaultPath',
          message: 'Obsidian vault path:',
          default: '~/Documents/Obsidian',
        }]);
        vaultPath = result.vaultPath;
      } else {
        console.log(chalk.dim(`Obsidian vault: ${vaultPath} (from existing config)`));
      }

      if (!projectFolder) {
        const result = await inquirerPrompt([{
          type: 'input',
          name: 'projectFolder',
          message: 'Project folder in vault:',
          default: `Projects/${projectName}`,
        }]);
        projectFolder = result.projectFolder;
      } else {
        console.log(chalk.dim(`Project folder: ${projectFolder} (from existing config)`));
      }

      // Apps configuration - prompt if missing or empty
      if (!apps || Object.keys(apps).length === 0) {
        apps = {};

        // Detect potential apps in monorepo
        const potentialApps: { name: string; path: string }[] = [];

        // Check for common monorepo patterns
        const appDirs = ['apps', 'packages', 'services'];
        for (const dir of appDirs) {
          const dirPath = join(process.cwd(), dir);
          if (existsSync(dirPath)) {
            const entries = readdirSync(dirPath);
            for (const entry of entries) {
              const entryPath = join(dirPath, entry);
              if (statSync(entryPath).isDirectory()) {
                if (existsSync(join(entryPath, 'package.json'))) {
                  potentialApps.push({ name: entry, path: `${dir}/${entry}` });
                }
              }
            }
          }
        }

        // Check for Makefile (common for backend)
        if (existsSync(join(process.cwd(), 'Makefile'))) {
          potentialApps.unshift({ name: 'backend', path: '.' });
        }

        if (potentialApps.length > 0) {
          console.log(chalk.blue('\nDetected apps:'));
          potentialApps.forEach(app => console.log(chalk.dim(`  - ${app.name} (${app.path})`)));
          console.log('');
        }

        // Ask about each app or let user add custom
        let addMoreApps = true;
        while (addMoreApps) {
          const { appName } = await inquirerPrompt([{
            type: 'input',
            name: 'appName',
            message: 'App name (e.g., web, backend, landing) or press enter to finish:',
            default: potentialApps.length > 0 && Object.keys(apps).length === 0 ? potentialApps[0].name : '',
          }]);

          if (!appName.trim()) {
            if (Object.keys(apps).length === 0) {
              apps['main'] = {
                path: '.',
                devCommand: 'npm run dev',
                devUrl: 'http://localhost:3000',
              };
              console.log(chalk.dim('Using default: main app at root'));
            }
            addMoreApps = false;
            continue;
          }

          const detected = potentialApps.find(a => a.name === appName.trim());

          const { appPath } = await inquirerPrompt([{
            type: 'input',
            name: 'appPath',
            message: `Path for ${appName}:`,
            default: detected?.path || '.',
          }]);

          const { appDevCommand } = await inquirerPrompt([{
            type: 'input',
            name: 'appDevCommand',
            message: `Dev command for ${appName}:`,
            default: appName === 'backend' ? 'make dev' : 'npm run dev',
          }]);

          const { appDevUrl } = await inquirerPrompt([{
            type: 'input',
            name: 'appDevUrl',
            message: `Dev URL for ${appName}:`,
            default: 'http://localhost:3000',
          }]);

          apps[appName.trim()] = {
            path: appPath,
            devCommand: appDevCommand,
            devUrl: appDevUrl,
          };

          console.log(chalk.green(`  ✓ Added ${appName}`));

          const idx = potentialApps.findIndex(a => a.name === appName.trim());
          if (idx >= 0) potentialApps.splice(idx, 1);
        }
      } else {
        console.log(chalk.dim(`Apps: ${Object.keys(apps).join(', ')} (from existing config)`));

        // Offer to add more apps
        const { addMore } = await inquirerPrompt([{
          type: 'confirm',
          name: 'addMore',
          message: 'Add or modify apps?',
          default: false,
        }]);

        if (addMore) {
          // Show existing apps
          console.log(chalk.blue('\nExisting apps:'));
          for (const [name, app] of Object.entries(apps)) {
            console.log(chalk.dim(`  - ${name}: ${(app as AppConfig).devCommand} (${(app as AppConfig).path})`));
          }
          console.log('');

          let addMoreApps = true;
          while (addMoreApps) {
            const { appName } = await inquirerPrompt([{
              type: 'input',
              name: 'appName',
              message: 'App name to add/modify (or press enter to finish):',
            }]);

            if (!appName.trim()) {
              addMoreApps = false;
              continue;
            }

            const existingApp = apps[appName.trim()] as AppConfig | undefined;

            const { appPath } = await inquirerPrompt([{
              type: 'input',
              name: 'appPath',
              message: `Path for ${appName}:`,
              default: existingApp?.path || '.',
            }]);

            const { appDevCommand } = await inquirerPrompt([{
              type: 'input',
              name: 'appDevCommand',
              message: `Dev command for ${appName}:`,
              default: existingApp?.devCommand || 'npm run dev',
            }]);

            const { appDevUrl } = await inquirerPrompt([{
              type: 'input',
              name: 'appDevUrl',
              message: `Dev URL for ${appName}:`,
              default: existingApp?.devUrl || 'http://localhost:3000',
            }]);

            apps[appName.trim()] = {
              path: appPath,
              devCommand: appDevCommand,
              devUrl: appDevUrl,
            };

            console.log(chalk.green(`  ✓ ${existingApp ? 'Updated' : 'Added'} ${appName}`));
          }
        }
      }

      // E2E setup - prompt if missing
      if (!e2eConfig) {
        const { e2eTool } = await inquirerPrompt([{
          type: 'list',
          name: 'e2eTool',
          message: 'E2E testing tool:',
          choices: ['playwright', 'cypress', 'puppeteer', 'none'],
        }]);

        e2eConfig = {
          tool: 'playwright',
          browser: 'chromium',
          headed: false,
          screenshotOnFail: true,
        };

        if (e2eTool !== 'none') {
          const { browser } = await inquirerPrompt([{
            type: 'list',
            name: 'browser',
            message: 'Browser:',
            choices: ['chromium', 'firefox', 'webkit'],
          }]);

          const { allowHeaded } = await inquirerPrompt([{
            type: 'confirm',
            name: 'allowHeaded',
            message: 'Allow headed mode for debugging?',
            default: true,
          }]);

          e2eConfig = {
            tool: e2eTool,
            browser,
            headed: allowHeaded,
            screenshotOnFail: true,
          };
        }
      } else {
        console.log(chalk.dim(`E2E: ${e2eConfig.tool} (from existing config)`));
      }

      config = {
        mode: mode as 'solo' | 'team',
        workMode: workMode as 'careful' | 'fast',
        source: {
          obsidian: true,
          github: mode === 'team',
        },
        create: {
          obsidian: true,
          github: mode === 'team',
        },
        obsidian: {
          vault: vaultPath || '~/Documents/Obsidian',
          project: projectFolder || `Projects/${projectName}`,
        },
        autoClose: mode === 'team' ? 'never' : 'ask',
        apps: apps || defaultConfig.apps,
        testing: {
          tdd: true,
          runner: 'jest',
          e2e: e2eConfig || defaultConfig.testing.e2e,
        },
      };

      if (mode === 'team') {
        config.github = {
          labels: {
            bug: 'bug',
            feature: 'enhancement',
            improvement: 'tech-debt',
          },
        };
      }
    }

    // Initialize based on repo type
    if (repoType === 'monorepo') {
      // Single repo init
      const skillCount = copySkills(process.cwd());
      console.log(chalk.green(`✓ Skills installed (${skillCount} files)`));

      createConfig(process.cwd(), config);
      console.log(chalk.green('✓ Config saved'));

      const createdClaudeMd = createClaudeMd(process.cwd(), projectName);
      if (createdClaudeMd) {
        console.log(chalk.green('✓ CLAUDE.md created'));
      }
    } else {
      // Multi-repo workspace
      const repos = getChildRepos();

      // Init workspace root
      const skillCount = copySkills(process.cwd());
      console.log(chalk.green(`✓ Skills installed at workspace root (${skillCount} files)`));

      createConfig(process.cwd(), config);
      console.log(chalk.green('✓ Config saved at workspace root'));

      // Create workspace CLAUDE.md
      const workspaceClaudeMd = `# ${projectName} Workspace

## Repositories

${repos.map(r => `- ${r}/`).join('\n')}

## Cross-Repo Work

Run Claude from this directory to work across repos.
Individual repos can be worked on separately.

## Active Session

Read \`.claw-session.md\` if it exists for current work context.
`;
      writeFileSync(join(process.cwd(), 'CLAUDE.md'), workspaceClaudeMd);
      console.log(chalk.green('✓ Workspace CLAUDE.md created'));

      // Init each child repo
      for (const repo of repos) {
        const repoPath = join(process.cwd(), repo);
        copySkills(repoPath);
        createConfig(repoPath, config);
        createClaudeMd(repoPath, repo);
        console.log(chalk.green(`✓ Initialized ${repo}/`));
      }
    }

    // Create Obsidian project folder structure
    const vaultPath = config.obsidian.vault.replace('~', homedir());
    const projectPath = join(vaultPath, config.obsidian.project);

    if (existsSync(vaultPath)) {
      mkdirSync(join(projectPath, 'bugs'), { recursive: true });
      mkdirSync(join(projectPath, 'features'), { recursive: true });
      mkdirSync(join(projectPath, 'improvements'), { recursive: true });
      mkdirSync(join(projectPath, 'attachments'), { recursive: true });
      console.log(chalk.green('✓ Obsidian folders created'));
    }

    // Done!
    console.log(chalk.green('\nDone!'));
    console.log(chalk.dim('\nIn Claude Code, try:'));
    console.log(chalk.cyan('  /run            ') + chalk.dim('- start a work session'));
    console.log(chalk.cyan('  /report-bug     ') + chalk.dim('- report a bug'));
    console.log(chalk.cyan('  /new-feature    ') + chalk.dim('- propose a feature'));
    console.log(chalk.cyan('  /new-improvement') + chalk.dim('- suggest an improvement'));
  });

// Parse and run
program.parse();
