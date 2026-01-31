// Test dependency tracking
import { DependencyManager, DependencyNode } from './dependencies.js';
import { Story } from './feature.js';
import { ProposedStory } from './breakdown.js';

describe('DependencyManager', () => {
  let manager: DependencyManager;

  beforeEach(() => {
    manager = new DependencyManager();
  });

  describe('buildFromStories', () => {
    it('should build dependency graph from stories', () => {
      const stories: Story[] = [
        { id: '1', title: 'Setup database', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'Create API', status: 'pending', scope: [], repos: [], estimatedHours: 4, blockedBy: ['1'] },
        { id: '3', title: 'Build UI', status: 'pending', scope: [], repos: [], estimatedHours: 3, blockedBy: ['2'] },
      ];

      const graph = manager.buildFromStories(stories);

      expect(graph.nodes.size).toBe(3);
      expect(graph.order).toEqual(['1', '2', '3']);

      const node1 = graph.nodes.get('1');
      expect(node1?.status).toBe('ready');
      expect(node1?.blocks).toEqual(['2']);

      const node2 = graph.nodes.get('2');
      expect(node2?.status).toBe('pending');
      expect(node2?.blockedBy).toEqual(['1']);
    });

    it('should mark stories with completed blockers as ready', () => {
      const stories: Story[] = [
        { id: '1', title: 'Setup database', status: 'complete', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'Create API', status: 'pending', scope: [], repos: [], estimatedHours: 4, blockedBy: ['1'] },
      ];

      const graph = manager.buildFromStories(stories);

      const node2 = graph.nodes.get('2');
      expect(node2?.status).toBe('ready');
    });
  });

  describe('buildFromProposedStories', () => {
    it('should build graph from proposed stories using titles', () => {
      const stories: ProposedStory[] = [
        { title: 'Setup database', scope: [], repos: [], estimatedHours: 2 },
        { title: 'Create API', scope: [], repos: [], estimatedHours: 4, dependsOn: ['Setup database'] },
        { title: 'Build UI', scope: [], repos: [], estimatedHours: 3, dependsOn: ['Create API'] },
      ];

      const graph = manager.buildFromProposedStories(stories);

      expect(graph.nodes.size).toBe(3);

      const node2 = graph.nodes.get('2');
      expect(node2?.blockedBy).toEqual(['1']);
    });
  });

  describe('getReadyStories', () => {
    it('should return stories with no unmet dependencies', () => {
      const stories: Story[] = [
        { id: '1', title: 'Story A', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'Story B', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '3', title: 'Story C', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
      ];

      manager.buildFromStories(stories);
      const ready = manager.getReadyStories();

      expect(ready).toHaveLength(2);
      expect(ready.map(n => n.id)).toEqual(expect.arrayContaining(['1', '2']));
    });
  });

  describe('getNextStory', () => {
    it('should return first ready story in topological order', () => {
      const stories: Story[] = [
        { id: '1', title: 'First', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'Second', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
      ];

      manager.buildFromStories(stories);
      const next = manager.getNextStory();

      expect(next?.id).toBe('1');
    });

    it('should return null if no stories are ready', () => {
      const stories: Story[] = [
        { id: '1', title: 'First', status: 'complete', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'Second', status: 'complete', scope: [], repos: [], estimatedHours: 2 },
      ];

      manager.buildFromStories(stories);
      const next = manager.getNextStory();

      expect(next).toBeNull();
    });
  });

  describe('markComplete', () => {
    it('should unblock dependent stories when completed', () => {
      const stories: Story[] = [
        { id: '1', title: 'First', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'Second', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
        { id: '3', title: 'Third', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
      ];

      manager.buildFromStories(stories);

      // Story 2 and 3 should be pending (blocked)
      expect(manager.getNode('2')?.status).toBe('pending');
      expect(manager.getNode('3')?.status).toBe('pending');

      // Complete story 1
      const unblocked = manager.markComplete('1');

      expect(unblocked).toHaveLength(2);
      expect(unblocked).toEqual(expect.arrayContaining(['2', '3']));
      expect(manager.getNode('2')?.status).toBe('ready');
      expect(manager.getNode('3')?.status).toBe('ready');
    });

    it('should not unblock if other blockers remain', () => {
      const stories: Story[] = [
        { id: '1', title: 'First', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'Second', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '3', title: 'Third', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1', '2'] },
      ];

      manager.buildFromStories(stories);

      // Complete only story 1
      const unblocked = manager.markComplete('1');

      expect(unblocked).toHaveLength(0);
      expect(manager.getNode('3')?.status).toBe('pending');
    });
  });

  describe('detectCircularDependencies', () => {
    it('should detect circular dependencies', () => {
      const stories: Story[] = [
        { id: '1', title: 'A', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['3'] },
        { id: '2', title: 'B', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
        { id: '3', title: 'C', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['2'] },
      ];

      manager.buildFromStories(stories);
      const cycles = manager.detectCircularDependencies();

      expect(cycles.length).toBeGreaterThan(0);
    });

    it('should return empty array for acyclic graph', () => {
      const stories: Story[] = [
        { id: '1', title: 'A', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'B', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
        { id: '3', title: 'C', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['2'] },
      ];

      manager.buildFromStories(stories);
      const cycles = manager.detectCircularDependencies();

      expect(cycles).toHaveLength(0);
    });
  });

  describe('getTopologicalOrder', () => {
    it('should return stories in dependency order', () => {
      const stories: Story[] = [
        { id: '3', title: 'Third', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['2'] },
        { id: '1', title: 'First', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'Second', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
      ];

      manager.buildFromStories(stories);
      const order = manager.getTopologicalOrder();

      // 1 must come before 2, 2 must come before 3
      expect(order.indexOf('1')).toBeLessThan(order.indexOf('2'));
      expect(order.indexOf('2')).toBeLessThan(order.indexOf('3'));
    });
  });

  describe('getProgress', () => {
    it('should return correct progress summary', () => {
      const stories: Story[] = [
        { id: '1', title: 'A', status: 'complete', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'B', status: 'in_progress', scope: [], repos: [], estimatedHours: 2 },
        { id: '3', title: 'C', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['2'] },
        { id: '4', title: 'D', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
      ];

      manager.buildFromStories(stories);
      const progress = manager.getProgress();

      expect(progress.total).toBe(4);
      expect(progress.complete).toBe(1);
      expect(progress.inProgress).toBe(1);
      expect(progress.ready).toBe(1); // Story 4
      expect(progress.pending).toBe(1); // Story 3 (blocked by 2)
    });
  });

  describe('getDependencyChain', () => {
    it('should return all ancestors of a story', () => {
      const stories: Story[] = [
        { id: '1', title: 'A', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'B', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
        { id: '3', title: 'C', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['2'] },
      ];

      manager.buildFromStories(stories);
      const chain = manager.getDependencyChain('3');

      expect(chain).toEqual(expect.arrayContaining(['1', '2']));
    });
  });

  describe('getDependentChain', () => {
    it('should return all descendants of a story', () => {
      const stories: Story[] = [
        { id: '1', title: 'A', status: 'pending', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'B', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
        { id: '3', title: 'C', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
      ];

      manager.buildFromStories(stories);
      const chain = manager.getDependentChain('1');

      expect(chain).toEqual(expect.arrayContaining(['2', '3']));
    });
  });

  describe('visualize', () => {
    it('should produce readable output', () => {
      const stories: Story[] = [
        { id: '1', title: 'Setup', status: 'complete', scope: [], repos: [], estimatedHours: 2 },
        { id: '2', title: 'Build', status: 'pending', scope: [], repos: [], estimatedHours: 2, blockedBy: ['1'] },
      ];

      manager.buildFromStories(stories);
      const output = manager.visualize();

      expect(output).toContain('✅');
      expect(output).toContain('📋');
      expect(output).toContain('Setup');
      expect(output).toContain('Build');
      expect(output).toContain('after: 1');
    });
  });
});
