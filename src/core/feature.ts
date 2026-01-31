// Feature management - epics, stories, and their lifecycle

import { ObsidianClient } from '../integrations/obsidian.js';
import { randomUUID } from 'crypto';

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

export interface SessionLog {
  date: string;
  action: string;
  details: string;
}

export class FeatureManager {
  private obsidian: ObsidianClient;
  private projectPath: string;

  constructor(obsidianVault: string, projectPath: string) {
    this.obsidian = new ObsidianClient(obsidianVault);
    this.projectPath = projectPath;
  }

  /**
   * Generate a slug from a title
   */
  private slugify(title: string): string {
    return title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '')
      .slice(0, 50);
  }

  /**
   * Get current date string
   */
  private getDateString(): string {
    return new Date().toISOString().split('T')[0];
  }

  /**
   * Get feature folder path
   */
  private getFeaturePath(featureId: string): string {
    return `${this.projectPath}/features/${featureId}`;
  }

  /**
   * Create a new feature (simple version - single story)
   */
  async create(title: string, description?: string): Promise<Feature> {
    const id = `${this.getDateString()}-${this.slugify(title)}`;
    const featurePath = this.getFeaturePath(id);

    // Create initial story (the whole feature as one story)
    const story: Story = {
      id: '1',
      title: title,
      scope: [description || title],
      repos: [], // Will be filled by discovery in Epic 2
      status: 'pending',
    };

    const feature: Feature = {
      id,
      title,
      description: description || title,
      status: 'planning',
      stories: [story],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    // Create feature folder and overview
    await this.obsidian.createDirectory(featurePath);

    const overviewContent = this.generateOverviewContent(feature);
    await this.obsidian.writeNote(`${featurePath}/_overview`, overviewContent);

    return feature;
  }

  /**
   * Generate overview markdown content
   */
  private generateOverviewContent(feature: Feature): string {
    const storiesTable = feature.stories
      .map(s => `| ${s.id} | ${s.title} | ${this.statusEmoji(s.status)} ${s.status} | ${s.branch || '-'} | ${s.scope.join(', ')} |`)
      .join('\n');

    const date = new Date().toISOString();

    return `# Feature: ${feature.title}

**ID:** ${feature.id}
**Status:** ${feature.status}
**Created:** ${feature.createdAt.toISOString()}

## Description

${feature.description}

## Stories

| # | Story | Status | Branch | Scope |
|---|-------|--------|--------|-------|
${storiesTable}

## Live Progress Tracker

| Metric | Value |
|--------|-------|
| Total Stories | ${feature.stories.length} |
| Completed | ${feature.stories.filter(s => s.status === 'complete').length} |
| In Progress | ${feature.stories.filter(s => s.status === 'in_progress').length} |
| Blocked | ${feature.stories.filter(s => s.status === 'blocked').length} |

**Current Story:** ${feature.stories.find(s => s.status !== 'complete' && s.status !== 'skipped')?.title || 'None'}
**Last Updated:** ${date}

## Session Log

| Date | Action | Details |
|------|--------|---------|
| ${date.split('T')[0]} | Created | Feature created |

---

*Managed by claw*
`;
  }

  /**
   * Get status emoji
   */
  private statusEmoji(status: StoryStatus): string {
    const emojis: Record<StoryStatus, string> = {
      pending: '⏳',
      in_progress: '🔄',
      complete: '✅',
      blocked: '🚫',
      skipped: '⏭️',
    };
    return emojis[status];
  }

  /**
   * Load a feature from Obsidian
   */
  async get(featureId: string): Promise<Feature | null> {
    const overviewPath = `${this.getFeaturePath(featureId)}/_overview`;
    const note = await this.obsidian.readNote(overviewPath);

    if (!note) return null;

    // Parse the overview to extract feature data
    return this.parseOverview(featureId, note.content);
  }

  /**
   * Parse overview content back to Feature object
   */
  private parseOverview(featureId: string, content: string): Feature {
    // Extract title
    const titleMatch = content.match(/^# Feature: (.+)$/m);
    const title = titleMatch?.[1] || featureId;

    // Extract status
    const statusMatch = content.match(/^\*\*Status:\*\* (.+)$/m);
    const status = (statusMatch?.[1] || 'planning') as Feature['status'];

    // Extract description
    const descMatch = content.match(/## Description\n\n([\s\S]*?)\n\n## Stories/);
    const description = descMatch?.[1]?.trim() || title;

    // Extract stories from table
    const stories: Story[] = [];
    const storyPattern = /\| (\d+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|/g;
    let match;
    while ((match = storyPattern.exec(content)) !== null) {
      const statusText = match[3].trim().replace(/^[^\s]+\s+/, ''); // Remove emoji
      stories.push({
        id: match[1],
        title: match[2].trim(),
        status: statusText as StoryStatus,
        branch: match[4].trim() === '-' ? undefined : match[4].trim(),
        scope: match[5].split(',').map(s => s.trim()),
        repos: [],
      });
    }

    // Extract dates
    const createdMatch = content.match(/^\*\*Created:\*\* (.+)$/m);
    const createdAt = createdMatch ? new Date(createdMatch[1]) : new Date();

    return {
      id: featureId,
      title,
      description,
      status,
      stories,
      createdAt,
      updatedAt: new Date(),
    };
  }

  /**
   * List all features
   */
  async list(): Promise<Feature[]> {
    const featuresPath = `${this.projectPath}/features`;
    const { dirs } = await this.obsidian.listDirectory(featuresPath);

    const features: Feature[] = [];
    for (const dir of dirs) {
      const feature = await this.get(dir);
      if (feature) features.push(feature);
    }

    return features.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  /**
   * Update a story's status
   */
  async updateStory(featureId: string, storyId: string, updates: Partial<Story>): Promise<Story | null> {
    const feature = await this.get(featureId);
    if (!feature) return null;

    const storyIndex = feature.stories.findIndex(s => s.id === storyId);
    if (storyIndex === -1) return null;

    // Update story
    const updatedStory = { ...feature.stories[storyIndex], ...updates };
    feature.stories[storyIndex] = updatedStory;
    feature.updatedAt = new Date();

    // Check if all stories complete
    if (feature.stories.every(s => s.status === 'complete' || s.status === 'skipped')) {
      feature.status = 'complete';
      feature.completedAt = new Date();
    } else if (feature.stories.some(s => s.status === 'in_progress')) {
      feature.status = 'executing';
    }

    // Update overview
    const overviewContent = this.generateOverviewContent(feature);
    await this.obsidian.writeNote(`${this.getFeaturePath(featureId)}/_overview`, overviewContent);

    return updatedStory;
  }

  /**
   * Append to session log
   */
  async logSession(featureId: string, action: string, details: string): Promise<void> {
    const overviewPath = `${this.getFeaturePath(featureId)}/_overview`;
    await this.obsidian.appendSessionLog(overviewPath, {
      date: this.getDateString(),
      action,
      details,
    });
  }

  /**
   * Update feature status
   */
  async updateStatus(featureId: string, status: Feature['status']): Promise<Feature | null> {
    const feature = await this.get(featureId);
    if (!feature) return null;

    feature.status = status;
    feature.updatedAt = new Date();

    const overviewContent = this.generateOverviewContent(feature);
    await this.obsidian.writeNote(`${this.getFeaturePath(featureId)}/_overview`, overviewContent);

    return feature;
  }

  // Methods for Epic 2 (to be implemented)
  async breakdown(featureId: string): Promise<BreakdownOption[]> {
    throw new Error('Not implemented - Story 2.2');
  }

  async refine(featureId: string, storyId: string, action: 'accept' | 'modify' | 'split' | 'skip', data?: any): Promise<Story> {
    throw new Error('Not implemented - Story 2.3');
  }
}
