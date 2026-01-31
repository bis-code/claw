// Workspace management - detecting and configuring multi-repo workspaces

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

  constructor(rootPath: string) {
    this.configPath = `${rootPath}/claw-workspace.json`;
  }

  async detect(): Promise<Repo[]> {
    // TODO: Implement repo detection (Story 1.2)
    // - Scan for .git directories
    // - Infer type from package.json, go.mod, etc.
    throw new Error('Not implemented - Story 1.2');
  }

  async load(): Promise<WorkspaceConfig> {
    // TODO: Load config from claw-workspace.json
    throw new Error('Not implemented - Story 1.2');
  }

  async save(config: WorkspaceConfig): Promise<void> {
    // TODO: Save config to claw-workspace.json
    throw new Error('Not implemented - Story 1.2');
  }

  async init(interactive: boolean = true): Promise<WorkspaceConfig> {
    // TODO: Full initialization flow (Story 1.2)
    throw new Error('Not implemented - Story 1.2');
  }
}
