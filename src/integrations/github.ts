// GitHub integration via gh CLI

import { spawn } from 'child_process';

export interface GitHubIssue {
  number: number;
  title: string;
  body: string;
  labels: string[];
  state: 'open' | 'closed';
}

export interface GitHubPR {
  number: number;
  title: string;
  body: string;
  state: 'open' | 'closed' | 'merged';
  branch: string;
  url: string;
}

export interface CreatePROptions {
  title: string;
  body: string;
  base?: string;
  draft?: boolean;
  labels?: string[];
}

export class GitHubClient {
  private workingDir: string;

  constructor(workingDir: string) {
    this.workingDir = workingDir;
  }

  /**
   * Run a gh CLI command
   */
  private async runGh(args: string[]): Promise<{ stdout: string; stderr: string; exitCode: number }> {
    return new Promise((resolve) => {
      const process = spawn('gh', args, {
        cwd: this.workingDir,
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      let stdout = '';
      let stderr = '';

      process.stdout?.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr?.on('data', (data) => {
        stderr += data.toString();
      });

      process.on('close', (code) => {
        resolve({ stdout, stderr, exitCode: code || 0 });
      });

      process.on('error', (err) => {
        resolve({ stdout, stderr: err.message, exitCode: 1 });
      });
    });
  }

  /**
   * Check if gh CLI is available and authenticated
   */
  async isAuthenticated(): Promise<boolean> {
    const result = await this.runGh(['auth', 'status']);
    return result.exitCode === 0;
  }

  /**
   * Get current branch name
   */
  async getCurrentBranch(): Promise<string> {
    const result = await this.runGh(['repo', 'view', '--json', 'name']);
    if (result.exitCode !== 0) {
      // Fallback to git
      const gitResult = await new Promise<string>((resolve) => {
        const proc = spawn('git', ['branch', '--show-current'], { cwd: this.workingDir });
        let output = '';
        proc.stdout?.on('data', (d) => output += d.toString());
        proc.on('close', () => resolve(output.trim()));
      });
      return gitResult;
    }
    return result.stdout.trim();
  }

  /**
   * Create a pull request
   */
  async createPR(options: CreatePROptions): Promise<GitHubPR> {
    const args = ['pr', 'create'];

    args.push('--title', options.title);
    args.push('--body', options.body);

    if (options.base) {
      args.push('--base', options.base);
    }

    if (options.draft) {
      args.push('--draft');
    }

    if (options.labels && options.labels.length > 0) {
      args.push('--label', options.labels.join(','));
    }

    const result = await this.runGh(args);

    if (result.exitCode !== 0) {
      throw new Error(`Failed to create PR: ${result.stderr}`);
    }

    // Parse the PR URL to get the number
    const url = result.stdout.trim();
    const prNumber = parseInt(url.split('/').pop() || '0', 10);

    return {
      number: prNumber,
      title: options.title,
      body: options.body,
      state: 'open',
      branch: await this.getCurrentBranch(),
      url,
    };
  }

  /**
   * Create an issue
   */
  async createIssue(title: string, body: string, labels: string[]): Promise<GitHubIssue> {
    const args = ['issue', 'create', '--title', title, '--body', body];

    if (labels.length > 0) {
      args.push('--label', labels.join(','));
    }

    const result = await this.runGh(args);

    if (result.exitCode !== 0) {
      throw new Error(`Failed to create issue: ${result.stderr}`);
    }

    // Parse the issue URL to get the number
    const url = result.stdout.trim();
    const issueNumber = parseInt(url.split('/').pop() || '0', 10);

    return {
      number: issueNumber,
      title,
      body,
      labels,
      state: 'open',
    };
  }

  /**
   * Close an issue
   */
  async closeIssue(issueNumber: number): Promise<void> {
    const result = await this.runGh(['issue', 'close', issueNumber.toString()]);

    if (result.exitCode !== 0) {
      throw new Error(`Failed to close issue: ${result.stderr}`);
    }
  }

  /**
   * List issues with optional label filter
   */
  async listIssues(labels?: string[]): Promise<GitHubIssue[]> {
    const args = ['issue', 'list', '--json', 'number,title,body,labels,state'];

    if (labels && labels.length > 0) {
      args.push('--label', labels.join(','));
    }

    const result = await this.runGh(args);

    if (result.exitCode !== 0) {
      throw new Error(`Failed to list issues: ${result.stderr}`);
    }

    try {
      const issues = JSON.parse(result.stdout);
      return issues.map((issue: any) => ({
        number: issue.number,
        title: issue.title,
        body: issue.body,
        labels: issue.labels?.map((l: any) => l.name) || [],
        state: issue.state,
      }));
    } catch {
      return [];
    }
  }

  /**
   * Get a specific issue
   */
  async getIssue(number: number): Promise<GitHubIssue | null> {
    const result = await this.runGh(['issue', 'view', number.toString(), '--json', 'number,title,body,labels,state']);

    if (result.exitCode !== 0) {
      return null;
    }

    try {
      const issue = JSON.parse(result.stdout);
      return {
        number: issue.number,
        title: issue.title,
        body: issue.body,
        labels: issue.labels?.map((l: any) => l.name) || [],
        state: issue.state,
      };
    } catch {
      return null;
    }
  }

  /**
   * Push current branch to remote
   */
  async pushBranch(): Promise<boolean> {
    const result = await new Promise<{ exitCode: number }>((resolve) => {
      const proc = spawn('git', ['push', '-u', 'origin', 'HEAD'], { cwd: this.workingDir });
      proc.on('close', (code) => resolve({ exitCode: code || 0 }));
      proc.on('error', () => resolve({ exitCode: 1 }));
    });
    return result.exitCode === 0;
  }

  /**
   * Get the default branch for the repo
   */
  async getDefaultBranch(): Promise<string> {
    const result = await this.runGh(['repo', 'view', '--json', 'defaultBranchRef']);

    if (result.exitCode !== 0) {
      return 'main'; // fallback
    }

    try {
      const data = JSON.parse(result.stdout);
      return data.defaultBranchRef?.name || 'main';
    } catch {
      return 'main';
    }
  }

  /**
   * Check if there's an existing PR for the current branch
   */
  async getExistingPR(): Promise<GitHubPR | null> {
    const result = await this.runGh(['pr', 'view', '--json', 'number,title,body,state,headRefName,url']);

    if (result.exitCode !== 0) {
      return null;
    }

    try {
      const pr = JSON.parse(result.stdout);
      return {
        number: pr.number,
        title: pr.title,
        body: pr.body,
        state: pr.state,
        branch: pr.headRefName,
        url: pr.url,
      };
    } catch {
      return null;
    }
  }
}
