// GitHub integration via gh CLI

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
}

export class GitHubClient {
  constructor(private repo?: string) {}

  async createIssue(title: string, body: string, labels: string[]): Promise<GitHubIssue> {
    // TODO: Create issue via gh CLI
    throw new Error('Not implemented');
  }

  async closeIssue(issueNumber: number): Promise<void> {
    // TODO: Close issue via gh CLI
    throw new Error('Not implemented');
  }

  async createPR(title: string, body: string, branch: string): Promise<GitHubPR> {
    // TODO: Create PR via gh CLI (Story 3.3)
    throw new Error('Not implemented - Story 3.3');
  }

  async listIssues(labels?: string[]): Promise<GitHubIssue[]> {
    // TODO: List issues via gh CLI
    throw new Error('Not implemented');
  }

  async getIssue(number: number): Promise<GitHubIssue | null> {
    // TODO: Get issue via gh CLI
    throw new Error('Not implemented');
  }
}
