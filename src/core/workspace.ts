// Workspace management - detecting and configuring multi-repo workspaces

import { readdir, readFile, writeFile, stat } from 'fs/promises';
import { join, basename, relative } from 'path';
import { existsSync } from 'fs';
import { spawn } from 'child_process';

export interface Repo {
  path: string;
  name: string;
  type: 'frontend' | 'backend' | 'shared' | 'web3' | 'monorepo' | 'unknown';
  framework?: string;
  language?: string;
}

export interface WorkspaceConfig {
  name: string;
  version: string;
  repos: Repo[];
  relationships: RepoRelationship[];
  obsidian?: {
    vault: string;
    project: string;
  };
  github?: {
    org?: string;
    createIssues: boolean;
    createPRs: boolean;
  };
  /** What Claude is allowed to do autonomously */
  permissions?: {
    /** Allow Claude to make git commits */
    commit: boolean;
    /** Allow Claude to push to remote */
    push: boolean;
    /** Allow Claude to create pull requests */
    createPR: boolean;
    /** Allow Claude to create GitHub issues */
    createIssue: boolean;
  };
}

export interface RepoRelationship {
  from: string;
  to: string;
  type: 'api-consumer' | 'abi-consumer' | 'shared-types' | 'depends-on';
  contract?: string;
}

export interface RepoContext {
  repo: Repo;
  recentFiles: string[];
  gitStatus: {
    branch: string;
    modified: string[];
    staged: string[];
    untracked: string[];
  };
  relevantFiles?: string[];
}

export interface CrossRepoContext {
  repos: RepoContext[];
  sharedTypes?: string[];
  apiContracts?: string[];
  changedContracts?: string[];
}

export interface MultiRepoCommit {
  message: string;
  repos: {
    repoPath: string;
    files: string[];
    success: boolean;
    error?: string;
    commitHash?: string;
  }[];
}

export class Workspace {
  private config: WorkspaceConfig | null = null;
  private configPath: string;
  private rootPath: string;

  constructor(rootPath: string) {
    this.rootPath = rootPath;
    this.configPath = join(rootPath, 'claw-workspace.json');
  }

  /**
   * Detect all git repositories in the workspace
   */
  async detect(): Promise<Repo[]> {
    const repos: Repo[] = [];

    // Check if current directory is a repo
    if (existsSync(join(this.rootPath, '.git'))) {
      const repo = await this.analyzeRepo(this.rootPath);
      repos.push(repo);
    }

    // Scan subdirectories (max depth 2)
    const entries = await readdir(this.rootPath, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory() || entry.name.startsWith('.') || entry.name === 'node_modules') {
        continue;
      }

      const subPath = join(this.rootPath, entry.name);
      if (existsSync(join(subPath, '.git'))) {
        const repo = await this.analyzeRepo(subPath);
        repos.push(repo);
      }
    }

    return repos;
  }

  /**
   * Analyze a repository to determine its type
   */
  private async analyzeRepo(repoPath: string): Promise<Repo> {
    const name = basename(repoPath);
    let type: Repo['type'] = 'unknown';
    let framework: string | undefined;
    let language: string | undefined;

    // Check for package.json (Node.js)
    const packageJsonPath = join(repoPath, 'package.json');
    if (existsSync(packageJsonPath)) {
      try {
        const pkg = JSON.parse(await readFile(packageJsonPath, 'utf-8'));
        language = 'typescript';

        const deps = { ...pkg.dependencies, ...pkg.devDependencies };

        // Detect frontend frameworks
        if (deps['react'] || deps['react-dom']) {
          type = 'frontend';
          framework = deps['next'] ? 'next' : 'react';
        } else if (deps['vue']) {
          type = 'frontend';
          framework = deps['nuxt'] ? 'nuxt' : 'vue';
        } else if (deps['@angular/core']) {
          type = 'frontend';
          framework = 'angular';
        } else if (deps['svelte']) {
          type = 'frontend';
          framework = deps['@sveltejs/kit'] ? 'sveltekit' : 'svelte';
        }
        // Detect backend frameworks
        else if (deps['express'] || deps['fastify'] || deps['koa'] || deps['hono']) {
          type = 'backend';
          framework = deps['express'] ? 'express' : deps['fastify'] ? 'fastify' : deps['koa'] ? 'koa' : 'hono';
        } else if (deps['@nestjs/core']) {
          type = 'backend';
          framework = 'nestjs';
        }
        // Detect shared/library
        else if (pkg.name?.includes('shared') || pkg.name?.includes('common') || pkg.name?.includes('types')) {
          type = 'shared';
        }
        // Detect monorepo
        else if (pkg.workspaces || existsSync(join(repoPath, 'lerna.json')) || existsSync(join(repoPath, 'pnpm-workspace.yaml'))) {
          type = 'monorepo';
        }
      } catch (e) {
        // Ignore JSON parse errors
      }
    }

    // Check for Go
    if (existsSync(join(repoPath, 'go.mod'))) {
      type = 'backend';
      language = 'go';
      framework = 'go';
    }

    // Check for Rust
    if (existsSync(join(repoPath, 'Cargo.toml'))) {
      type = 'backend';
      language = 'rust';
      framework = 'rust';
    }

    // Check for Python
    if (existsSync(join(repoPath, 'pyproject.toml')) || existsSync(join(repoPath, 'requirements.txt'))) {
      language = 'python';
      if (existsSync(join(repoPath, 'manage.py'))) {
        type = 'backend';
        framework = 'django';
      } else if (existsSync(join(repoPath, 'app.py')) || existsSync(join(repoPath, 'main.py'))) {
        type = 'backend';
        framework = 'fastapi';
      }
    }

    // Check for Web3/Solidity
    if (existsSync(join(repoPath, 'hardhat.config.js')) || existsSync(join(repoPath, 'hardhat.config.ts'))) {
      type = 'web3';
      framework = 'hardhat';
      language = 'solidity';
    } else if (existsSync(join(repoPath, 'foundry.toml'))) {
      type = 'web3';
      framework = 'foundry';
      language = 'solidity';
    }

    return {
      path: repoPath,
      name,
      type,
      framework,
      language,
    };
  }

  /**
   * Infer relationships between repos
   */
  async inferRelationships(repos: Repo[]): Promise<RepoRelationship[]> {
    const relationships: RepoRelationship[] = [];

    // Find frontend-backend relationships
    const frontends = repos.filter(r => r.type === 'frontend');
    const backends = repos.filter(r => r.type === 'backend');
    const web3 = repos.filter(r => r.type === 'web3');

    // Frontend consumes backend API
    for (const fe of frontends) {
      for (const be of backends) {
        relationships.push({
          from: fe.name,
          to: be.name,
          type: 'api-consumer',
        });
      }
      // Frontend consumes web3 ABI
      for (const w3 of web3) {
        relationships.push({
          from: fe.name,
          to: w3.name,
          type: 'abi-consumer',
        });
      }
    }

    return relationships;
  }

  /**
   * Load existing workspace config
   */
  async load(): Promise<WorkspaceConfig | null> {
    if (!existsSync(this.configPath)) {
      return null;
    }

    try {
      const content = await readFile(this.configPath, 'utf-8');
      this.config = JSON.parse(content);
      return this.config;
    } catch (e) {
      return null;
    }
  }

  /**
   * Save workspace config
   */
  async save(config: WorkspaceConfig): Promise<void> {
    this.config = config;
    await writeFile(this.configPath, JSON.stringify(config, null, 2));
  }

  /**
   * Check if workspace is already initialized
   */
  isInitialized(): boolean {
    return existsSync(this.configPath);
  }

  /**
   * Get the config path
   */
  getConfigPath(): string {
    return this.configPath;
  }

  /**
   * Initialize workspace with detected repos
   */
  async init(interactive: boolean = true): Promise<WorkspaceConfig> {
    const repos = await this.detect();
    const relationships = await this.inferRelationships(repos);

    const config: WorkspaceConfig = {
      name: basename(this.rootPath),
      version: '1.0.0',
      repos,
      relationships,
      obsidian: {
        vault: '~/Documents/Obsidian',
        project: `Projects/${basename(this.rootPath)}`,
      },
      github: {
        createIssues: true,
        createPRs: true,
      },
    };

    // In non-interactive mode, just save
    if (!interactive) {
      await this.save(config);
    }

    return config;
  }

  // ─────────────────────────────────────────────────────────────
  // Multi-Repo Operations (Epic 5)
  // ─────────────────────────────────────────────────────────────

  /**
   * Run a git command in a repo and return output
   */
  private async runGit(repoPath: string, args: string[]): Promise<string> {
    return new Promise((resolve, reject) => {
      const proc = spawn('git', args, { cwd: repoPath });
      let stdout = '';
      let stderr = '';

      proc.stdout?.on('data', (data) => { stdout += data.toString(); });
      proc.stderr?.on('data', (data) => { stderr += data.toString(); });

      proc.on('close', (code) => {
        if (code === 0) {
          resolve(stdout.trim());
        } else {
          reject(new Error(stderr || `Git command failed with code ${code}`));
        }
      });
    });
  }

  /**
   * Get git status for a repo
   */
  async getRepoGitStatus(repoPath: string): Promise<RepoContext['gitStatus']> {
    try {
      const branch = await this.runGit(repoPath, ['branch', '--show-current']);
      const status = await this.runGit(repoPath, ['status', '--porcelain']);

      const modified: string[] = [];
      const staged: string[] = [];
      const untracked: string[] = [];

      for (const line of status.split('\n').filter(Boolean)) {
        const indexStatus = line[0];
        const workStatus = line[1];
        const file = line.slice(3);

        if (indexStatus !== ' ' && indexStatus !== '?') {
          staged.push(file);
        }
        if (workStatus === 'M' || workStatus === 'D') {
          modified.push(file);
        }
        if (indexStatus === '?') {
          untracked.push(file);
        }
      }

      return { branch, modified, staged, untracked };
    } catch (error) {
      return { branch: 'unknown', modified: [], staged: [], untracked: [] };
    }
  }

  /**
   * Get recent files changed in a repo
   */
  async getRecentFiles(repoPath: string, days: number = 7): Promise<string[]> {
    try {
      const since = new Date();
      since.setDate(since.getDate() - days);
      const sinceStr = since.toISOString().split('T')[0];

      const output = await this.runGit(repoPath, [
        'log',
        `--since=${sinceStr}`,
        '--name-only',
        '--pretty=format:',
      ]);

      const files = output
        .split('\n')
        .filter(Boolean)
        .filter((file, index, arr) => arr.indexOf(file) === index);

      return files.slice(0, 50); // Limit to 50 most recent
    } catch {
      return [];
    }
  }

  /**
   * Get context for a single repo
   */
  async getRepoContext(repo: Repo): Promise<RepoContext> {
    const gitStatus = await this.getRepoGitStatus(repo.path);
    const recentFiles = await this.getRecentFiles(repo.path);

    return {
      repo,
      recentFiles,
      gitStatus,
    };
  }

  /**
   * Get cross-repo context for a feature
   * This provides context to Claude about the entire workspace
   */
  async getCrossRepoContext(repoNames?: string[]): Promise<CrossRepoContext> {
    if (!this.config) {
      await this.load();
    }

    const repos = this.config?.repos || [];
    const targetRepos = repoNames
      ? repos.filter(r => repoNames.includes(r.name))
      : repos;

    const contexts = await Promise.all(targetRepos.map(r => this.getRepoContext(r)));

    // Find shared types and API contracts
    const sharedTypes: string[] = [];
    const apiContracts: string[] = [];
    const changedContracts: string[] = [];

    for (const ctx of contexts) {
      const typesFiles = ctx.recentFiles.filter(f =>
        f.includes('types') || f.includes('.d.ts') || f.endsWith('.interface.ts')
      );
      sharedTypes.push(...typesFiles.map(f => `${ctx.repo.name}:${f}`));

      const apiFiles = ctx.recentFiles.filter(f =>
        f.includes('api') || f.includes('routes') || f.includes('endpoint')
      );
      apiContracts.push(...apiFiles.map(f => `${ctx.repo.name}:${f}`));

      // Check if any contracts were modified
      const modifiedContracts = [...ctx.gitStatus.modified, ...ctx.gitStatus.staged].filter(f =>
        f.includes('types') || f.includes('api') || f.includes('.d.ts')
      );
      changedContracts.push(...modifiedContracts.map(f => `${ctx.repo.name}:${f}`));
    }

    return {
      repos: contexts,
      sharedTypes: [...new Set(sharedTypes)],
      apiContracts: [...new Set(apiContracts)],
      changedContracts: [...new Set(changedContracts)],
    };
  }

  /**
   * Stage files in a repo
   */
  async stageFiles(repoPath: string, files: string[]): Promise<boolean> {
    try {
      if (files.length === 0) {
        // Stage all modified files
        await this.runGit(repoPath, ['add', '-u']);
      } else {
        await this.runGit(repoPath, ['add', ...files]);
      }
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Commit in a single repo
   */
  async commitRepo(repoPath: string, message: string): Promise<{ success: boolean; hash?: string; error?: string }> {
    try {
      await this.runGit(repoPath, ['commit', '-m', message]);
      const hash = await this.runGit(repoPath, ['rev-parse', '--short', 'HEAD']);
      return { success: true, hash };
    } catch (error) {
      return { success: false, error: error instanceof Error ? error.message : String(error) };
    }
  }

  /**
   * Coordinate commits across multiple repos
   * Ensures atomic-like behavior with rollback on failure
   */
  async coordinatedCommit(
    repoChanges: { repoPath: string; files: string[] }[],
    message: string
  ): Promise<MultiRepoCommit> {
    const result: MultiRepoCommit = {
      message,
      repos: [],
    };

    const committed: string[] = [];

    try {
      for (const change of repoChanges) {
        // Stage files
        const staged = await this.stageFiles(change.repoPath, change.files);
        if (!staged) {
          result.repos.push({
            repoPath: change.repoPath,
            files: change.files,
            success: false,
            error: 'Failed to stage files',
          });
          continue;
        }

        // Check if there's anything to commit
        const status = await this.getRepoGitStatus(change.repoPath);
        if (status.staged.length === 0) {
          result.repos.push({
            repoPath: change.repoPath,
            files: change.files,
            success: true,
            commitHash: 'no-changes',
          });
          continue;
        }

        // Commit
        const commitResult = await this.commitRepo(change.repoPath, message);
        result.repos.push({
          repoPath: change.repoPath,
          files: change.files,
          success: commitResult.success,
          commitHash: commitResult.hash,
          error: commitResult.error,
        });

        if (commitResult.success) {
          committed.push(change.repoPath);
        }
      }

      // Check if we need to rollback (if some succeeded and some failed)
      const failures = result.repos.filter(r => !r.success && r.error !== 'Failed to stage files');
      if (failures.length > 0 && committed.length > 0) {
        // Rollback committed repos
        for (const repoPath of committed) {
          try {
            await this.runGit(repoPath, ['reset', '--soft', 'HEAD~1']);
          } catch {
            // Best effort rollback
          }
        }

        // Mark all as rolled back
        for (const repo of result.repos) {
          if (repo.success && repo.commitHash !== 'no-changes') {
            repo.success = false;
            repo.error = 'Rolled back due to failure in another repo';
            repo.commitHash = undefined;
          }
        }
      }
    } catch (error) {
      // General error - mark all as failed
      for (const repo of result.repos) {
        if (repo.success && repo.commitHash !== 'no-changes') {
          repo.success = false;
          repo.error = error instanceof Error ? error.message : String(error);
        }
      }
    }

    return result;
  }

  /**
   * Create coordinated branches across repos
   */
  async createBranchesInRepos(repoNames: string[], branchName: string): Promise<{ repo: string; success: boolean; error?: string }[]> {
    const repos = this.config?.repos.filter(r => repoNames.includes(r.name)) || [];
    const results: { repo: string; success: boolean; error?: string }[] = [];

    for (const repo of repos) {
      try {
        // Check if branch already exists
        try {
          await this.runGit(repo.path, ['rev-parse', '--verify', branchName]);
          // Branch exists, checkout
          await this.runGit(repo.path, ['checkout', branchName]);
        } catch {
          // Branch doesn't exist, create it
          await this.runGit(repo.path, ['checkout', '-b', branchName]);
        }
        results.push({ repo: repo.name, success: true });
      } catch (error) {
        results.push({
          repo: repo.name,
          success: false,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }

    return results;
  }

  /**
   * Get affected repos for a set of file changes
   */
  getAffectedRepos(changedFiles: string[]): Repo[] {
    if (!this.config) return [];

    const affected = new Set<string>();

    for (const file of changedFiles) {
      for (const repo of this.config.repos) {
        if (file.startsWith(repo.path) || file.includes(repo.name)) {
          affected.add(repo.name);
        }
      }
    }

    // Also add repos that consume changed repos (via relationships)
    for (const rel of this.config.relationships) {
      if (affected.has(rel.to)) {
        affected.add(rel.from);
      }
    }

    return this.config.repos.filter(r => affected.has(r.name));
  }

  /**
   * Format cross-repo context as a prompt for Claude
   */
  formatContextForPrompt(context: CrossRepoContext): string {
    const lines: string[] = ['## Workspace Context', ''];

    for (const repoCtx of context.repos) {
      lines.push(`### ${repoCtx.repo.name} (${repoCtx.repo.type})`);
      lines.push(`- Framework: ${repoCtx.repo.framework || 'N/A'}`);
      lines.push(`- Branch: ${repoCtx.gitStatus.branch}`);

      if (repoCtx.gitStatus.modified.length > 0) {
        lines.push(`- Modified: ${repoCtx.gitStatus.modified.slice(0, 5).join(', ')}`);
      }
      if (repoCtx.gitStatus.staged.length > 0) {
        lines.push(`- Staged: ${repoCtx.gitStatus.staged.slice(0, 5).join(', ')}`);
      }

      lines.push('');
    }

    if (context.changedContracts && context.changedContracts.length > 0) {
      lines.push('### Changed Contracts (⚠️ May require coordination)');
      lines.push(context.changedContracts.map(c => `- ${c}`).join('\n'));
      lines.push('');
    }

    return lines.join('\n');
  }
}
