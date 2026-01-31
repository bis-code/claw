// Dependency tracking for stories

import { Story } from './feature.js';
import { ProposedStory } from './breakdown.js';

export interface DependencyNode {
  id: string;
  title: string;
  status: 'pending' | 'ready' | 'in_progress' | 'complete' | 'blocked';
  blockedBy: string[];
  blocks: string[];
}

export interface DependencyGraph {
  nodes: Map<string, DependencyNode>;
  order: string[]; // Topological order
}

export class DependencyManager {
  private nodes: Map<string, DependencyNode> = new Map();

  /**
   * Build dependency graph from stories
   */
  buildFromStories(stories: Story[]): DependencyGraph {
    this.nodes.clear();

    // First pass: create all nodes
    for (const story of stories) {
      // Map story status to dependency node status
      let nodeStatus: DependencyNode['status'] = 'pending';
      if (story.status === 'complete') {
        nodeStatus = 'complete';
      } else if (story.status === 'in_progress') {
        nodeStatus = 'in_progress';
      } else if (story.status === 'blocked') {
        nodeStatus = 'blocked';
      }

      this.nodes.set(story.id, {
        id: story.id,
        title: story.title,
        status: nodeStatus,
        blockedBy: story.blockedBy || [],
        blocks: [],
      });
    }

    // Second pass: populate blocks (reverse of blockedBy)
    for (const story of stories) {
      if (story.blockedBy) {
        for (const blockerId of story.blockedBy) {
          const blockerNode = this.nodes.get(blockerId);
          if (blockerNode) {
            blockerNode.blocks.push(story.id);
          }
        }
      }
    }

    // Third pass: update ready status
    this.updateReadyStatus();

    return {
      nodes: this.nodes,
      order: this.getTopologicalOrder(),
    };
  }

  /**
   * Build dependency graph from proposed stories (using titles as IDs)
   */
  buildFromProposedStories(stories: ProposedStory[]): DependencyGraph {
    this.nodes.clear();

    // Create title-to-index mapping
    const titleToId = new Map<string, string>();
    stories.forEach((story, index) => {
      titleToId.set(story.title, (index + 1).toString());
    });

    // First pass: create all nodes
    for (let i = 0; i < stories.length; i++) {
      const story = stories[i];
      const id = (i + 1).toString();
      const blockedBy: string[] = [];

      // Convert title dependencies to IDs
      if (story.dependsOn) {
        for (const dep of story.dependsOn) {
          const depId = titleToId.get(dep);
          if (depId) {
            blockedBy.push(depId);
          }
        }
      }

      this.nodes.set(id, {
        id,
        title: story.title,
        status: 'pending',
        blockedBy,
        blocks: [],
      });
    }

    // Second pass: populate blocks
    for (const [id, node] of this.nodes) {
      for (const blockerId of node.blockedBy) {
        const blockerNode = this.nodes.get(blockerId);
        if (blockerNode) {
          blockerNode.blocks.push(id);
        }
      }
    }

    // Update ready status
    this.updateReadyStatus();

    return {
      nodes: this.nodes,
      order: this.getTopologicalOrder(),
    };
  }

  /**
   * Update ready status for all nodes
   */
  private updateReadyStatus(): void {
    for (const node of this.nodes.values()) {
      if (node.status === 'complete' || node.status === 'in_progress') {
        continue;
      }

      const allBlockersComplete = node.blockedBy.every(blockerId => {
        const blocker = this.nodes.get(blockerId);
        return blocker?.status === 'complete';
      });

      node.status = allBlockersComplete ? 'ready' : 'pending';
    }
  }

  /**
   * Get stories that are ready to work on (no unmet dependencies)
   */
  getReadyStories(): DependencyNode[] {
    return Array.from(this.nodes.values()).filter(n => n.status === 'ready');
  }

  /**
   * Get next story to work on (first ready story in topological order)
   */
  getNextStory(): DependencyNode | null {
    const order = this.getTopologicalOrder();
    for (const id of order) {
      const node = this.nodes.get(id);
      if (node?.status === 'ready') {
        return node;
      }
    }
    return null;
  }

  /**
   * Mark a story as in progress
   */
  markInProgress(storyId: string): void {
    const node = this.nodes.get(storyId);
    if (node && node.status === 'ready') {
      node.status = 'in_progress';
    }
  }

  /**
   * Mark a story as complete and update dependents
   */
  markComplete(storyId: string): string[] {
    const node = this.nodes.get(storyId);
    if (!node) return [];

    node.status = 'complete';

    // Find newly unblocked stories
    const unblocked: string[] = [];
    for (const blockedId of node.blocks) {
      const blockedNode = this.nodes.get(blockedId);
      if (!blockedNode) continue;

      const allBlockersComplete = blockedNode.blockedBy.every(bid => {
        const blocker = this.nodes.get(bid);
        return blocker?.status === 'complete';
      });

      if (allBlockersComplete && blockedNode.status === 'pending') {
        blockedNode.status = 'ready';
        unblocked.push(blockedId);
      }
    }

    return unblocked;
  }

  /**
   * Mark a story as blocked (external blocker)
   */
  markBlocked(storyId: string): void {
    const node = this.nodes.get(storyId);
    if (node) {
      node.status = 'blocked';
    }
  }

  /**
   * Detect circular dependencies
   */
  detectCircularDependencies(): string[][] {
    const cycles: string[][] = [];
    const visited = new Set<string>();
    const recursionStack = new Set<string>();
    const path: string[] = [];

    const dfs = (nodeId: string): boolean => {
      visited.add(nodeId);
      recursionStack.add(nodeId);
      path.push(nodeId);

      const node = this.nodes.get(nodeId);
      if (node) {
        for (const blockerId of node.blockedBy) {
          if (!visited.has(blockerId)) {
            if (dfs(blockerId)) {
              return true;
            }
          } else if (recursionStack.has(blockerId)) {
            // Found cycle
            const cycleStart = path.indexOf(blockerId);
            cycles.push(path.slice(cycleStart));
            return true;
          }
        }
      }

      path.pop();
      recursionStack.delete(nodeId);
      return false;
    };

    for (const nodeId of this.nodes.keys()) {
      if (!visited.has(nodeId)) {
        dfs(nodeId);
      }
    }

    return cycles;
  }

  /**
   * Get topological order (respecting dependencies)
   */
  getTopologicalOrder(): string[] {
    const result: string[] = [];
    const visited = new Set<string>();
    const temp = new Set<string>();

    const visit = (nodeId: string): boolean => {
      if (temp.has(nodeId)) {
        return false; // Cycle detected
      }
      if (visited.has(nodeId)) {
        return true;
      }

      temp.add(nodeId);

      const node = this.nodes.get(nodeId);
      if (node) {
        for (const blockerId of node.blockedBy) {
          if (!visit(blockerId)) {
            return false;
          }
        }
      }

      temp.delete(nodeId);
      visited.add(nodeId);
      result.push(nodeId);
      return true;
    };

    for (const nodeId of this.nodes.keys()) {
      if (!visited.has(nodeId)) {
        visit(nodeId);
      }
    }

    return result;
  }

  /**
   * Get progress summary
   */
  getProgress(): { total: number; complete: number; inProgress: number; ready: number; blocked: number; pending: number } {
    let complete = 0;
    let inProgress = 0;
    let ready = 0;
    let blocked = 0;
    let pending = 0;

    for (const node of this.nodes.values()) {
      switch (node.status) {
        case 'complete': complete++; break;
        case 'in_progress': inProgress++; break;
        case 'ready': ready++; break;
        case 'blocked': blocked++; break;
        case 'pending': pending++; break;
      }
    }

    return {
      total: this.nodes.size,
      complete,
      inProgress,
      ready,
      blocked,
      pending,
    };
  }

  /**
   * Get dependency chain for a story (all ancestors)
   */
  getDependencyChain(storyId: string): string[] {
    const chain: string[] = [];
    const visited = new Set<string>();

    const collectDeps = (id: string) => {
      if (visited.has(id)) return;
      visited.add(id);

      const node = this.nodes.get(id);
      if (node) {
        for (const blockerId of node.blockedBy) {
          collectDeps(blockerId);
          if (!chain.includes(blockerId)) {
            chain.push(blockerId);
          }
        }
      }
    };

    collectDeps(storyId);
    return chain;
  }

  /**
   * Get stories that depend on a given story (all descendants)
   */
  getDependentChain(storyId: string): string[] {
    const chain: string[] = [];
    const visited = new Set<string>();

    const collectDeps = (id: string) => {
      if (visited.has(id)) return;
      visited.add(id);

      const node = this.nodes.get(id);
      if (node) {
        for (const blockedId of node.blocks) {
          if (!chain.includes(blockedId)) {
            chain.push(blockedId);
          }
          collectDeps(blockedId);
        }
      }
    };

    collectDeps(storyId);
    return chain;
  }

  /**
   * Get node by ID
   */
  getNode(storyId: string): DependencyNode | undefined {
    return this.nodes.get(storyId);
  }

  /**
   * Get all nodes
   */
  getAllNodes(): DependencyNode[] {
    return Array.from(this.nodes.values());
  }

  /**
   * Visualize dependencies as text
   */
  visualize(): string {
    const lines: string[] = [];
    const order = this.getTopologicalOrder();

    for (const id of order) {
      const node = this.nodes.get(id);
      if (!node) continue;

      const statusIcon = {
        complete: '✅',
        in_progress: '🔄',
        ready: '📋',
        blocked: '🚫',
        pending: '⏳',
      }[node.status];

      const deps = node.blockedBy.length > 0
        ? ` (after: ${node.blockedBy.join(', ')})`
        : '';

      lines.push(`${statusIcon} ${id}. ${node.title}${deps}`);
    }

    return lines.join('\n');
  }
}
