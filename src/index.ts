// Claw v3 - Minimal bootstrapper for Claude Code skills
// No exports needed - this is just a CLI tool

// Re-export types for programmatic usage if needed
export interface AppConfig {
  path: string;
  devCommand: string;
  devUrl: string;
  e2eCommand?: string;
}

export interface ClawConfig {
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
