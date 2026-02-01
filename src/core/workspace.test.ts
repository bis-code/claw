// Tests for workspace multi-repo functionality

import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { Workspace, Repo, WorkspaceConfig, CrossRepoContext, RepoContext } from './workspace.js';
import { mkdtemp, rm, mkdir, writeFile } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { execSync } from 'child_process';

describe('Workspace', () => {
  let tempDir: string;
  let workspace: Workspace;

  beforeEach(async () => {
    tempDir = await mkdtemp(join(tmpdir(), 'claw-workspace-test-'));
    workspace = new Workspace(tempDir);
  });

  afterEach(async () => {
    await rm(tempDir, { recursive: true, force: true });
  });

  describe('detect', () => {
    it('should detect a single git repo', async () => {
      // Initialize git in temp dir
      execSync('git init', { cwd: tempDir });
      execSync('git config user.email "test@test.com"', { cwd: tempDir });
      execSync('git config user.name "Test"', { cwd: tempDir });

      const repos = await workspace.detect();
      expect(repos.length).toBe(1);
    });

    it('should detect multiple repos in subdirectories', async () => {
      // Create two repo dirs
      const repo1 = join(tempDir, 'frontend');
      const repo2 = join(tempDir, 'backend');
      await mkdir(repo1);
      await mkdir(repo2);

      execSync('git init', { cwd: repo1 });
      execSync('git init', { cwd: repo2 });

      const repos = await workspace.detect();
      expect(repos.length).toBe(2);
    });
  });

  describe('analyzeRepo', () => {
    it('should detect frontend React project', async () => {
      execSync('git init', { cwd: tempDir });

      await writeFile(join(tempDir, 'package.json'), JSON.stringify({
        name: 'test-frontend',
        dependencies: { react: '18.0.0' }
      }));

      const repos = await workspace.detect();
      expect(repos[0].type).toBe('frontend');
      expect(repos[0].framework).toBe('react');
    });

    it('should detect backend Express project', async () => {
      execSync('git init', { cwd: tempDir });

      await writeFile(join(tempDir, 'package.json'), JSON.stringify({
        name: 'test-backend',
        dependencies: { express: '4.0.0' }
      }));

      const repos = await workspace.detect();
      expect(repos[0].type).toBe('backend');
      expect(repos[0].framework).toBe('express');
    });

    it('should detect Go project', async () => {
      execSync('git init', { cwd: tempDir });

      await writeFile(join(tempDir, 'go.mod'), 'module test\ngo 1.21');

      const repos = await workspace.detect();
      expect(repos[0].type).toBe('backend');
      expect(repos[0].language).toBe('go');
    });
  });

  describe('inferRelationships', () => {
    it('should infer frontend-backend relationship', async () => {
      const repos: Repo[] = [
        { path: '/frontend', name: 'frontend', type: 'frontend' },
        { path: '/backend', name: 'backend', type: 'backend' },
      ];

      const relationships = await workspace.inferRelationships(repos);
      expect(relationships.length).toBe(1);
      expect(relationships[0].from).toBe('frontend');
      expect(relationships[0].to).toBe('backend');
      expect(relationships[0].type).toBe('api-consumer');
    });

    it('should infer frontend-web3 relationship', async () => {
      const repos: Repo[] = [
        { path: '/frontend', name: 'frontend', type: 'frontend' },
        { path: '/contracts', name: 'contracts', type: 'web3' },
      ];

      const relationships = await workspace.inferRelationships(repos);
      const abiRel = relationships.find(r => r.type === 'abi-consumer');
      expect(abiRel).toBeDefined();
      expect(abiRel?.from).toBe('frontend');
      expect(abiRel?.to).toBe('contracts');
    });
  });

  describe('config management', () => {
    it('should save and load config', async () => {
      const config: WorkspaceConfig = {
        name: 'test-workspace',
        version: '1.0.0',
        repos: [{ path: tempDir, name: 'test', type: 'backend' }],
        relationships: [],
      };

      await workspace.save(config);
      const loaded = await workspace.load();

      expect(loaded).not.toBeNull();
      expect(loaded?.name).toBe('test-workspace');
    });

    it('should report initialization status', async () => {
      expect(workspace.isInitialized()).toBe(false);

      await workspace.save({
        name: 'test',
        version: '1.0.0',
        repos: [],
        relationships: [],
      });

      expect(workspace.isInitialized()).toBe(true);
    });
  });

  describe('multi-repo operations', () => {
    it('should get repo git status', async () => {
      // Initialize repo
      execSync('git init', { cwd: tempDir });
      execSync('git config user.email "test@test.com"', { cwd: tempDir });
      execSync('git config user.name "Test"', { cwd: tempDir });

      // Create and commit a file
      await writeFile(join(tempDir, 'test.txt'), 'initial');
      execSync('git add test.txt && git commit -m "Initial"', { cwd: tempDir });

      // Stage a modification
      await writeFile(join(tempDir, 'test.txt'), 'modified');
      execSync('git add test.txt', { cwd: tempDir }); // Now it's staged

      const status = await workspace.getRepoGitStatus(tempDir);
      expect(status.branch).toBeDefined();
      // File should be staged
      expect(status.staged).toContain('test.txt');
    });

    it('should stage and commit in a repo', async () => {
      // Initialize repo
      execSync('git init', { cwd: tempDir });
      execSync('git config user.email "test@test.com"', { cwd: tempDir });
      execSync('git config user.name "Test"', { cwd: tempDir });

      // Create a file
      await writeFile(join(tempDir, 'test.txt'), 'content');

      // Stage and commit
      const staged = await workspace.stageFiles(tempDir, ['test.txt']);
      expect(staged).toBe(true);

      const result = await workspace.commitRepo(tempDir, 'Test commit');
      expect(result.success).toBe(true);
      expect(result.hash).toBeDefined();
    });

    it('should format context for prompt', () => {
      const context: CrossRepoContext = {
        repos: [
          {
            repo: { path: '/frontend', name: 'frontend', type: 'frontend', framework: 'react' },
            recentFiles: ['src/App.tsx'],
            gitStatus: { branch: 'main', modified: ['src/App.tsx'], staged: [], untracked: [] },
          },
          {
            repo: { path: '/backend', name: 'backend', type: 'backend', framework: 'express' },
            recentFiles: ['src/index.ts'],
            gitStatus: { branch: 'main', modified: [], staged: ['src/api.ts'], untracked: [] },
          },
        ],
        changedContracts: ['backend:src/types/api.d.ts'],
      };

      const prompt = workspace.formatContextForPrompt(context);
      expect(prompt).toContain('frontend');
      expect(prompt).toContain('backend');
      expect(prompt).toContain('react');
      expect(prompt).toContain('express');
      expect(prompt).toContain('Changed Contracts');
    });
  });

  describe('coordinated commits', () => {
    let repo1: string;
    let repo2: string;

    beforeEach(async () => {
      // Create two repos
      repo1 = join(tempDir, 'repo1');
      repo2 = join(tempDir, 'repo2');
      await mkdir(repo1);
      await mkdir(repo2);

      for (const repo of [repo1, repo2]) {
        execSync('git init', { cwd: repo });
        execSync('git config user.email "test@test.com"', { cwd: repo });
        execSync('git config user.name "Test"', { cwd: repo });
        await writeFile(join(repo, 'README.md'), '# Test');
        execSync('git add README.md && git commit -m "Initial"', { cwd: repo });
      }
    });

    it('should commit across multiple repos', async () => {
      // Make changes in both repos
      await writeFile(join(repo1, 'file1.txt'), 'content1');
      await writeFile(join(repo2, 'file2.txt'), 'content2');

      const result = await workspace.coordinatedCommit(
        [
          { repoPath: repo1, files: ['file1.txt'] },
          { repoPath: repo2, files: ['file2.txt'] },
        ],
        'Coordinated commit'
      );

      expect(result.repos.length).toBe(2);
      expect(result.repos.every(r => r.success)).toBe(true);
    });

    it('should handle no changes gracefully', async () => {
      const result = await workspace.coordinatedCommit(
        [{ repoPath: repo1, files: [] }],
        'Empty commit'
      );

      expect(result.repos.length).toBe(1);
      expect(result.repos[0].success).toBe(true);
      expect(result.repos[0].commitHash).toBe('no-changes');
    });
  });

  describe('branch management', () => {
    let repo1: string;

    beforeEach(async () => {
      repo1 = join(tempDir, 'repo1');
      await mkdir(repo1);
      execSync('git init', { cwd: repo1 });
      execSync('git config user.email "test@test.com"', { cwd: repo1 });
      execSync('git config user.name "Test"', { cwd: repo1 });
      await writeFile(join(repo1, 'README.md'), '# Test');
      execSync('git add README.md && git commit -m "Initial"', { cwd: repo1 });

      // Save config with this repo
      await workspace.save({
        name: 'test',
        version: '1.0.0',
        repos: [{ path: repo1, name: 'repo1', type: 'backend' }],
        relationships: [],
      });
    });

    it('should create branches in repos', async () => {
      const results = await workspace.createBranchesInRepos(['repo1'], 'feature/test');

      expect(results.length).toBe(1);
      expect(results[0].success).toBe(true);

      // Verify branch was created
      const branch = execSync('git branch --show-current', { cwd: repo1 }).toString().trim();
      expect(branch).toBe('feature/test');
    });

    it('should switch to existing branch', async () => {
      // Create branch first
      execSync('git checkout -b feature/existing', { cwd: repo1 });
      execSync('git checkout master || git checkout main', { cwd: repo1 });

      const results = await workspace.createBranchesInRepos(['repo1'], 'feature/existing');

      expect(results.length).toBe(1);
      expect(results[0].success).toBe(true);
    });
  });
});
