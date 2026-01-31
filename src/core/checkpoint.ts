// Checkpoint system for session state persistence

import { ObsidianClient } from '../integrations/obsidian.js';
import { SessionState, SessionConfig } from './session.js';
import { Feature } from './feature.js';

export interface CheckpointData {
  version: string;
  timestamp: string;
  featureId: string;
  sessionState: {
    startTime: string;
    storiesCompleted: number;
    storiesBlocked: number;
    totalIterations: number;
    currentStoryId: string | null;
    status: SessionState['status'];
    blockerReason?: string;
    pendingQuestion?: string;
  };
  config: Partial<SessionConfig>;
  storyProgress: Record<string, {
    status: string;
    iterations: number;
    pr?: number;
  }>;
}

export class CheckpointManager {
  private obsidian: ObsidianClient;
  private projectPath: string;

  constructor(vaultPath: string, projectPath: string) {
    this.obsidian = new ObsidianClient(vaultPath);
    this.projectPath = projectPath;
  }

  /**
   * Get checkpoint path for a feature
   */
  private getCheckpointPath(featureId: string): string {
    return `${this.projectPath}/features/${featureId}/_checkpoint`;
  }

  /**
   * Save session checkpoint
   */
  async saveCheckpoint(
    feature: Feature,
    state: SessionState,
    config: SessionConfig
  ): Promise<void> {
    const checkpoint: CheckpointData = {
      version: '1.0',
      timestamp: new Date().toISOString(),
      featureId: feature.id,
      sessionState: {
        startTime: state.startTime.toISOString(),
        storiesCompleted: state.storiesCompleted,
        storiesBlocked: state.storiesBlocked,
        totalIterations: state.totalIterations,
        currentStoryId: state.currentStory?.id || null,
        status: state.status,
        blockerReason: state.blockerReason,
        pendingQuestion: state.pendingQuestion,
      },
      config: {
        maxHours: config.maxHours,
        maxStories: config.maxStories,
        stopOnBlocker: config.stopOnBlocker,
        pauseBetweenStories: config.pauseBetweenStories,
        model: config.model,
        iterateUntilGreen: config.iterateUntilGreen,
        maxIterations: config.maxIterations,
        createPRPerStory: config.createPRPerStory,
        createPROnComplete: config.createPROnComplete,
      },
      storyProgress: {},
    };

    // Collect story progress
    for (const story of feature.stories) {
      checkpoint.storyProgress[story.id] = {
        status: story.status,
        iterations: story.iterations || 1,
        pr: story.pr,
      };
    }

    // Write checkpoint as JSON frontmatter + readable content
    const content = this.formatCheckpoint(checkpoint);
    await this.obsidian.writeNote(this.getCheckpointPath(feature.id), content);
  }

  /**
   * Load session checkpoint
   */
  async loadCheckpoint(featureId: string): Promise<CheckpointData | null> {
    const note = await this.obsidian.readNote(this.getCheckpointPath(featureId));
    if (!note) return null;

    try {
      // Parse JSON from frontmatter
      const match = note.content.match(/```json\n([\s\S]*?)\n```/);
      if (!match) return null;

      return JSON.parse(match[1]);
    } catch {
      return null;
    }
  }

  /**
   * Delete checkpoint after successful completion
   */
  async deleteCheckpoint(featureId: string): Promise<void> {
    try {
      await this.obsidian.deleteNote(this.getCheckpointPath(featureId));
    } catch {
      // Ignore if doesn't exist
    }
  }

  /**
   * Check if a checkpoint exists
   */
  async hasCheckpoint(featureId: string): Promise<boolean> {
    return this.obsidian.exists(this.getCheckpointPath(featureId));
  }

  /**
   * Format checkpoint as readable markdown with JSON
   */
  private formatCheckpoint(checkpoint: CheckpointData): string {
    const date = new Date(checkpoint.timestamp);
    const formattedDate = date.toLocaleString();

    const statusEmoji = {
      running: '🔄',
      paused: '⏸️',
      completed: '✅',
      blocked: '🚫',
      timeout: '⏰',
      error: '❌',
    }[checkpoint.sessionState.status];

    const storyList = Object.entries(checkpoint.storyProgress)
      .map(([id, data]) => {
        const emoji = {
          pending: '⏳',
          in_progress: '🔄',
          complete: '✅',
          blocked: '🚫',
          skipped: '⏭️',
        }[data.status] || '❓';
        return `- ${emoji} Story ${id}: ${data.status}${data.iterations > 1 ? ` (${data.iterations} iterations)` : ''}`;
      })
      .join('\n');

    return `# Session Checkpoint

${statusEmoji} **Status:** ${checkpoint.sessionState.status}
**Last Updated:** ${formattedDate}
**Stories Completed:** ${checkpoint.sessionState.storiesCompleted}
**Stories Blocked:** ${checkpoint.sessionState.storiesBlocked}
**Total Iterations:** ${checkpoint.sessionState.totalIterations}

## Story Progress

${storyList}

${checkpoint.sessionState.blockerReason ? `\n## Blocker\n\n${checkpoint.sessionState.blockerReason}\n` : ''}

${checkpoint.sessionState.pendingQuestion ? `\n## Pending Question\n\n${checkpoint.sessionState.pendingQuestion}\n` : ''}

## Checkpoint Data

\`\`\`json
${JSON.stringify(checkpoint, null, 2)}
\`\`\`

---
*This checkpoint can be used to resume the session with \`claw resume ${checkpoint.featureId}\`*
`;
  }

  /**
   * Calculate remaining time from checkpoint
   */
  getRemainingTime(checkpoint: CheckpointData): number {
    const startTime = new Date(checkpoint.sessionState.startTime);
    const elapsed = (Date.now() - startTime.getTime()) / 1000 / 60 / 60; // hours
    const maxHours = checkpoint.config.maxHours || 4;
    return Math.max(0, maxHours - elapsed);
  }

  /**
   * Check if checkpoint is resumable
   */
  isResumable(checkpoint: CheckpointData): boolean {
    const status = checkpoint.sessionState.status;
    return status === 'paused' || status === 'running' || status === 'blocked';
  }
}
