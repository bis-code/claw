// Tests for progress reporting

import { describe, it, expect, beforeEach } from '@jest/globals';
import { ProgressReporter, createSpinner } from './progress.js';

describe('ProgressReporter', () => {
  let reporter: ProgressReporter;

  beforeEach(() => {
    reporter = new ProgressReporter(5, false); // Disable console logging for tests
  });

  describe('initialization', () => {
    it('should initialize with correct stats', () => {
      const stats = reporter.getStats();
      expect(stats.totalStories).toBe(5);
      expect(stats.completedStories).toBe(0);
      expect(stats.blockedStories).toBe(0);
      expect(stats.totalIterations).toBe(0);
    });
  });

  describe('event tracking', () => {
    it('should track session start', () => {
      reporter.sessionStart('Test Feature');
      const events = reporter.getEvents();
      expect(events.length).toBe(1);
      expect(events[0].type).toBe('start');
    });

    it('should track story completion', () => {
      reporter.storyComplete('1', 3, 2);
      const stats = reporter.getStats();
      expect(stats.completedStories).toBe(1);
      expect(stats.totalIterations).toBe(2);
    });

    it('should track story blocked', () => {
      reporter.storyBlocked('1', 'Missing dependency');
      const stats = reporter.getStats();
      expect(stats.blockedStories).toBe(1);
    });

    it('should track iterations', () => {
      reporter.iteration('1', 3, 'Test failures');
      const events = reporter.getEvents();
      const iterEvent = events.find(e => e.type === 'iteration');
      expect(iterEvent).toBeDefined();
      expect(iterEvent?.message).toContain('Iteration 3');
    });
  });

  describe('callbacks', () => {
    it('should call registered callbacks', () => {
      const events: any[] = [];
      reporter.onProgress((event) => {
        events.push(event);
      });

      reporter.sessionStart('Test');
      reporter.storyComplete('1', 1, 1);

      expect(events.length).toBe(2);
      expect(events[0].type).toBe('start');
      expect(events[1].type).toBe('story_complete');
    });

    it('should not fail if callback throws', () => {
      reporter.onProgress(() => {
        throw new Error('Callback error');
      });

      // Should not throw
      expect(() => reporter.sessionStart('Test')).not.toThrow();
    });
  });

  describe('estimated time', () => {
    it('should calculate estimated remaining time', () => {
      // Complete a story
      reporter.storyComplete('1', 1, 1);

      // Get stats - should have estimated time
      const stats = reporter.getStats();
      expect(stats.estimatedRemainingMinutes).toBeDefined();
    });
  });

  describe('log formatting', () => {
    it('should format events as log', () => {
      reporter.sessionStart('Test Feature');
      reporter.storyStart('1', 'Story One');
      reporter.storyComplete('1', 2, 1);

      const log = reporter.formatLog();
      expect(log).toContain('start');
      expect(log).toContain('story_start');
      expect(log).toContain('story_complete');
    });
  });
});

describe('createSpinner', () => {
  it('should create spinner with all methods', () => {
    const spinner = createSpinner('Test');
    expect(typeof spinner.start).toBe('function');
    expect(typeof spinner.stop).toBe('function');
    expect(typeof spinner.update).toBe('function');
    expect(typeof spinner.succeed).toBe('function');
    expect(typeof spinner.fail).toBe('function');
  });

  it('should start and stop without error', () => {
    const spinner = createSpinner('Test');
    spinner.start();
    spinner.stop();
  });

  it('should update text', () => {
    const spinner = createSpinner('Initial');
    spinner.update('Updated');
    // Text is internal, just verify no error
  });

  it('should handle succeed', () => {
    const spinner = createSpinner('Test');
    spinner.start();
    spinner.succeed('Done');
  });

  it('should handle fail', () => {
    const spinner = createSpinner('Test');
    spinner.start();
    spinner.fail('Error');
  });
});
