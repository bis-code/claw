// Workspace management - detecting and configuring multi-repo workspaces

import { readdir, readFile, writeFile, stat } from 'fs/promises';
import { join, basename } from 'path';
import { existsSync } from 'fs';

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
}

export interface RepoRelationship {
  from: string;
  to: string;
  type: 'api-consumer' | 'abi-consumer' | 'shared-types' | 'depends-on';
  contract?: string;
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
}
