// Feature management - epics, stories, and their lifecycle

export type StoryStatus = 'pending' | 'in_progress' | 'complete' | 'blocked' | 'skipped';

export interface Story {
  id: string;
  title: string;
  scope: string[];
  repos: string[];
  status: StoryStatus;
  branch?: string;
  pr?: number;
  blockedBy?: string[];
  estimatedHours?: number;
  actualHours?: number;
  iterations?: number;
}

export interface Feature {
  id: string;
  title: string;
  description: string;
  status: 'planning' | 'executing' | 'complete' | 'paused';
  stories: Story[];
  createdAt: Date;
  updatedAt: Date;
  completedAt?: Date;
}

export interface BreakdownOption {
  name: string;
  description: string;
  stories: Omit<Story, 'id' | 'status'>[];
  recommended?: boolean;
}

export class FeatureManager {
  constructor(private obsidianPath: string) {}

  async create(title: string): Promise<Feature> {
    // TODO: Create feature, run discovery, generate breakdown options (Epic 2)
    throw new Error('Not implemented - Epic 2');
  }

  async breakdown(featureId: string): Promise<BreakdownOption[]> {
    // TODO: Generate breakdown options using multi-agent analysis (Story 2.2)
    throw new Error('Not implemented - Story 2.2');
  }

  async refine(featureId: string, storyId: string, action: 'accept' | 'modify' | 'split' | 'skip', data?: any): Promise<Story> {
    // TODO: Refine individual story (Story 2.3)
    throw new Error('Not implemented - Story 2.3');
  }

  async get(featureId: string): Promise<Feature | null> {
    // TODO: Load feature from Obsidian
    throw new Error('Not implemented');
  }

  async list(): Promise<Feature[]> {
    // TODO: List all features from Obsidian
    throw new Error('Not implemented');
  }

  async updateStory(featureId: string, storyId: string, updates: Partial<Story>): Promise<Story> {
    // TODO: Update story status in Obsidian
    throw new Error('Not implemented - Story 3.4');
  }
}
