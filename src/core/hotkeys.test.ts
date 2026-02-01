// Tests for hotkey handling

import { jest, describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { HotkeyManager, HotkeyAction, createHotkeyAwareSpinner } from './hotkeys.js';
import { DependencyManager } from './dependencies.js';

describe('HotkeyManager', () => {
  let hotkeyManager: HotkeyManager;
  let callbacks: Record<string, jest.Mock>;

  beforeEach(() => {
    callbacks = {
      onPause: jest.fn(),
      onSkip: jest.fn(),
      onAbort: jest.fn(),
      onAsk: jest.fn(),
      onPivot: jest.fn(),
      onStatus: jest.fn(),
    };

    hotkeyManager = new HotkeyManager(callbacks);
  });

  afterEach(() => {
    hotkeyManager.stop();
  });

  describe('constructor', () => {
    it('should create manager with default handlers', () => {
      expect(hotkeyManager).toBeDefined();
      expect(hotkeyManager.isListening()).toBe(false);
    });
  });

  describe('registerHandler', () => {
    it('should allow registering custom handlers', () => {
      const customHandler = jest.fn<() => void>();
      hotkeyManager.registerHandler({
        key: 'x',
        action: 'abort' as HotkeyAction,
        description: 'Custom action',
        handler: customHandler,
      });
      // Custom handler registered successfully
      expect(hotkeyManager).toBeDefined();
    });
  });

  describe('start/stop', () => {
    it('should track active state', () => {
      expect(hotkeyManager.isListening()).toBe(false);
      // Note: start() requires TTY which isn't available in tests
      // We can only test that the flag is initially false
    });

    it('should be safe to call stop when not active', () => {
      expect(() => hotkeyManager.stop()).not.toThrow();
    });

    it('should be safe to call stop multiple times', () => {
      hotkeyManager.stop();
      hotkeyManager.stop();
      expect(hotkeyManager.isListening()).toBe(false);
    });
  });

  describe('suspend/resume', () => {
    it('should suspend and resume without error', () => {
      // Suspend/resume should not throw even when not active
      expect(() => hotkeyManager.suspend()).not.toThrow();
      expect(() => hotkeyManager.resume()).not.toThrow();
    });
  });
});

describe('createHotkeyAwareSpinner', () => {
  it('should create spinner with expected interface', () => {
    const spinner = createHotkeyAwareSpinner('Test');

    expect(spinner).toHaveProperty('start');
    expect(spinner).toHaveProperty('stop');
    expect(spinner).toHaveProperty('succeed');
    expect(spinner).toHaveProperty('fail');
    expect(spinner).toHaveProperty('text');
    expect(typeof spinner.start).toBe('function');
    expect(typeof spinner.stop).toBe('function');
  });

  it('should allow getting and setting text', () => {
    const spinner = createHotkeyAwareSpinner('Initial');
    expect(spinner.text).toBe('Initial');

    spinner.text = 'Updated';
    expect(spinner.text).toBe('Updated');
  });

  it('should start and stop without error', () => {
    const spinner = createHotkeyAwareSpinner('Test');
    spinner.start();
    spinner.stop();
  });

  it('should handle succeed and fail', () => {
    const spinner = createHotkeyAwareSpinner('Test');
    spinner.start();
    spinner.succeed('Done');

    const spinner2 = createHotkeyAwareSpinner('Test 2');
    spinner2.start();
    spinner2.fail('Error');
  });
});

describe('DependencyManager pivot methods', () => {
  it('should add a new node dynamically', () => {
    const manager = new DependencyManager();
    manager.buildFromStories([
      { id: '1', title: 'Story 1', scope: [], repos: [], status: 'pending' },
    ]);

    manager.addNode('2', 'New Story', []);
    const node = manager.getNode('2');
    expect(node).toBeDefined();
    expect(node?.status).toBe('ready');
  });

  it('should add node with dependencies', () => {
    const manager = new DependencyManager();
    manager.buildFromStories([
      { id: '1', title: 'Story 1', scope: [], repos: [], status: 'pending' },
    ]);

    manager.addNode('2', 'Dependent Story', ['1']);
    const node = manager.getNode('2');
    expect(node?.status).toBe('pending');
    expect(node?.blockedBy).toEqual(['1']);
  });

  it('should clear dependencies for prioritization', () => {
    const manager = new DependencyManager();
    manager.buildFromStories([
      { id: '1', title: 'Story 1', scope: [], repos: [], status: 'pending' },
      { id: '2', title: 'Story 2', scope: [], repos: [], status: 'pending', blockedBy: ['1'] },
    ]);

    const nodeBefore = manager.getNode('2');
    expect(nodeBefore?.blockedBy).toEqual(['1']);

    manager.clearDependencies('2');
    const nodeAfter = manager.getNode('2');
    expect(nodeAfter?.blockedBy).toEqual([]);
    expect(nodeAfter?.status).toBe('ready');
  });

  it('should reset a story to ready state', () => {
    const manager = new DependencyManager();
    manager.buildFromStories([
      { id: '1', title: 'Story 1', scope: [], repos: [], status: 'complete' },
      { id: '2', title: 'Story 2', scope: [], repos: [], status: 'in_progress', blockedBy: ['1'] },
    ]);

    manager.resetStory('2');
    const node = manager.getNode('2');
    expect(node?.status).toBe('ready'); // Ready because blocker is complete
  });

  it('should reset to pending if blockers not complete', () => {
    const manager = new DependencyManager();
    manager.buildFromStories([
      { id: '1', title: 'Story 1', scope: [], repos: [], status: 'pending' },
      { id: '2', title: 'Story 2', scope: [], repos: [], status: 'in_progress', blockedBy: ['1'] },
    ]);

    manager.resetStory('2');
    const node = manager.getNode('2');
    expect(node?.status).toBe('pending'); // Pending because blocker not complete
  });
});
