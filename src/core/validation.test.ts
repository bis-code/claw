// Tests for validation module

import { describe, it, expect } from '@jest/globals';
import {
  validateWorkspaceConfig,
  validateSessionConfig,
  validateFeature,
  validateStory,
  formatValidationResult,
  assertValid,
} from './validation.js';
import { WorkspaceConfig } from './workspace.js';
import { SessionConfig } from './session.js';
import { Feature, Story } from './feature.js';

describe('validateWorkspaceConfig', () => {
  it('should pass valid config', () => {
    const config: WorkspaceConfig = {
      name: 'test-workspace',
      version: '1.0.0',
      repos: [{
        path: process.cwd(),
        name: 'claw',
        type: 'backend',
      }],
      relationships: [],
    };

    const result = validateWorkspaceConfig(config);
    expect(result.valid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  it('should fail on missing name', () => {
    const config: Partial<WorkspaceConfig> = {
      version: '1.0.0',
      repos: [],
      relationships: [],
    };

    const result = validateWorkspaceConfig(config);
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.code === 'MISSING_NAME')).toBe(true);
  });

  it('should fail on no repos', () => {
    const config: Partial<WorkspaceConfig> = {
      name: 'test',
      version: '1.0.0',
      repos: [],
      relationships: [],
    };

    const result = validateWorkspaceConfig(config);
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.code === 'NO_REPOS')).toBe(true);
  });

  it('should warn on missing obsidian vault', () => {
    const config: Partial<WorkspaceConfig> = {
      name: 'test',
      version: '1.0.0',
      repos: [{ path: process.cwd(), name: 'test', type: 'backend' }],
      relationships: [],
      obsidian: {
        vault: '/nonexistent/path',
        project: 'test',
      },
    };

    const result = validateWorkspaceConfig(config);
    expect(result.warnings.some(w => w.field === 'obsidian.vault')).toBe(true);
  });
});

describe('validateSessionConfig', () => {
  it('should pass valid config', () => {
    const config: Partial<SessionConfig> = {
      maxHours: 4,
      model: 'sonnet',
    };

    const result = validateSessionConfig(config);
    expect(result.valid).toBe(true);
  });

  it('should fail on invalid hours', () => {
    const config: Partial<SessionConfig> = {
      maxHours: -1,
    };

    const result = validateSessionConfig(config);
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.code === 'INVALID_HOURS')).toBe(true);
  });

  it('should warn on long sessions', () => {
    const config: Partial<SessionConfig> = {
      maxHours: 48,
    };

    const result = validateSessionConfig(config);
    expect(result.warnings.some(w => w.field === 'maxHours')).toBe(true);
  });

  it('should fail on invalid model', () => {
    const config: Partial<SessionConfig> = {
      maxHours: 4,
      model: 'invalid' as any,
    };

    const result = validateSessionConfig(config);
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.code === 'INVALID_MODEL')).toBe(true);
  });
});

describe('validateFeature', () => {
  it('should pass valid feature', () => {
    const feature: Partial<Feature> = {
      id: 'test-feature',
      title: 'Test Feature Title',
      stories: [{
        id: '1',
        title: 'Story One Title',
        scope: ['scope item'],
        repos: [],
        status: 'pending',
      }],
    };

    const result = validateFeature(feature);
    expect(result.valid).toBe(true);
  });

  it('should fail on invalid ID', () => {
    const feature: Partial<Feature> = {
      id: 'Invalid ID!',
      title: 'Test',
    };

    const result = validateFeature(feature);
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.code === 'INVALID_ID')).toBe(true);
  });

  it('should warn on no stories', () => {
    const feature: Partial<Feature> = {
      id: 'test',
      title: 'Test Feature',
      stories: [],
    };

    const result = validateFeature(feature);
    expect(result.warnings.some(w => w.field === 'stories')).toBe(true);
  });

  it('should detect circular dependencies', () => {
    const feature: Partial<Feature> = {
      id: 'test',
      title: 'Test Feature',
      stories: [
        { id: '1', title: 'Story 1 Title', scope: [], repos: [], status: 'pending', blockedBy: ['2'] },
        { id: '2', title: 'Story 2 Title', scope: [], repos: [], status: 'pending', blockedBy: ['1'] },
      ],
    };

    const result = validateFeature(feature);
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.code === 'CIRCULAR_DEPS')).toBe(true);
  });
});

describe('validateStory', () => {
  it('should pass valid story', () => {
    const story: Partial<Story> = {
      id: '1',
      title: 'Implement user authentication',
      scope: ['auth', 'login'],
      status: 'pending',
    };

    const result = validateStory(story);
    expect(result.valid).toBe(true);
  });

  it('should fail on missing ID', () => {
    const story: Partial<Story> = {
      title: 'Test story',
    };

    const result = validateStory(story);
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.code === 'MISSING_ID')).toBe(true);
  });

  it('should warn on short title', () => {
    const story: Partial<Story> = {
      id: '1',
      title: 'Short',
      scope: [],
    };

    const result = validateStory(story);
    expect(result.warnings.some(w => w.field === 'title')).toBe(true);
  });

  it('should warn on no scope', () => {
    const story: Partial<Story> = {
      id: '1',
      title: 'A longer story title here',
      scope: [],
    };

    const result = validateStory(story);
    expect(result.warnings.some(w => w.field === 'scope')).toBe(true);
  });
});

describe('formatValidationResult', () => {
  it('should format passed result', () => {
    const result = { valid: true, errors: [], warnings: [] };
    const formatted = formatValidationResult(result);
    expect(formatted).toContain('Validation passed');
  });

  it('should format failed result with errors', () => {
    const result = {
      valid: false,
      errors: [{ field: 'name', message: 'Required', code: 'MISSING' }],
      warnings: [],
    };
    const formatted = formatValidationResult(result);
    expect(formatted).toContain('Validation failed');
    expect(formatted).toContain('name: Required');
  });

  it('should format warnings with suggestions', () => {
    const result = {
      valid: true,
      errors: [],
      warnings: [{
        field: 'hours',
        message: 'Too long',
        suggestion: 'Use shorter sessions',
      }],
    };
    const formatted = formatValidationResult(result);
    expect(formatted).toContain('hours: Too long');
    expect(formatted).toContain('Use shorter sessions');
  });
});

describe('assertValid', () => {
  it('should return value on valid', () => {
    const config = { maxHours: 4 };
    const result = assertValid(config, validateSessionConfig, 'session config');
    expect(result).toBe(config);
  });

  it('should throw on invalid', () => {
    const config = { maxHours: -1 };
    expect(() => assertValid(config, validateSessionConfig, 'session config'))
      .toThrow('Invalid session config');
  });
});
