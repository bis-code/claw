// Configuration and input validation

import { existsSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';
import { WorkspaceConfig, Repo } from './workspace.js';
import { SessionConfig } from './session.js';
import { Feature, Story } from './feature.js';

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings: ValidationWarning[];
}

export interface ValidationError {
  field: string;
  message: string;
  code: string;
}

export interface ValidationWarning {
  field: string;
  message: string;
  suggestion?: string;
}

/**
 * Validate workspace configuration
 */
export function validateWorkspaceConfig(config: Partial<WorkspaceConfig>): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  // Required fields
  if (!config.name) {
    errors.push({ field: 'name', message: 'Workspace name is required', code: 'MISSING_NAME' });
  }

  if (!config.version) {
    errors.push({ field: 'version', message: 'Version is required', code: 'MISSING_VERSION' });
  }

  // Repos validation
  if (!config.repos || config.repos.length === 0) {
    errors.push({ field: 'repos', message: 'At least one repository is required', code: 'NO_REPOS' });
  } else {
    for (const repo of config.repos) {
      const repoErrors = validateRepo(repo);
      errors.push(...repoErrors.map(e => ({ ...e, field: `repos.${repo.name}.${e.field}` })));
    }
  }

  // Obsidian validation
  if (config.obsidian) {
    const vaultPath = config.obsidian.vault?.replace('~', homedir());
    if (vaultPath && !existsSync(vaultPath)) {
      warnings.push({
        field: 'obsidian.vault',
        message: `Obsidian vault not found: ${vaultPath}`,
        suggestion: 'Create the vault directory or update the path',
      });
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Validate a single repo
 */
function validateRepo(repo: Partial<Repo>): ValidationError[] {
  const errors: ValidationError[] = [];

  if (!repo.path) {
    errors.push({ field: 'path', message: 'Repository path is required', code: 'MISSING_PATH' });
  } else if (!existsSync(repo.path)) {
    errors.push({ field: 'path', message: `Repository not found: ${repo.path}`, code: 'REPO_NOT_FOUND' });
  } else if (!existsSync(join(repo.path, '.git'))) {
    errors.push({ field: 'path', message: `Not a git repository: ${repo.path}`, code: 'NOT_GIT_REPO' });
  }

  if (!repo.name) {
    errors.push({ field: 'name', message: 'Repository name is required', code: 'MISSING_NAME' });
  }

  if (!repo.type) {
    errors.push({ field: 'type', message: 'Repository type is required', code: 'MISSING_TYPE' });
  }

  return errors;
}

/**
 * Validate session configuration
 */
export function validateSessionConfig(config: Partial<SessionConfig>): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  // maxHours is optional (undefined = no limit), but if provided must be positive
  if (config.maxHours !== undefined && config.maxHours <= 0) {
    errors.push({ field: 'maxHours', message: 'maxHours must be a positive number', code: 'INVALID_HOURS' });
  } else if (config.maxHours !== undefined && config.maxHours > 24) {
    warnings.push({
      field: 'maxHours',
      message: 'Session longer than 24 hours',
      suggestion: 'Consider breaking into multiple sessions',
    });
  }

  // Optional fields validation
  if (config.maxStories !== undefined && config.maxStories <= 0) {
    errors.push({ field: 'maxStories', message: 'maxStories must be a positive number', code: 'INVALID_STORIES' });
  }

  if (config.maxIterations !== undefined && config.maxIterations <= 0) {
    errors.push({ field: 'maxIterations', message: 'maxIterations must be a positive number', code: 'INVALID_ITERATIONS' });
  } else if (config.maxIterations && config.maxIterations > 10) {
    warnings.push({
      field: 'maxIterations',
      message: 'High iteration limit may indicate unclear requirements',
      suggestion: 'Consider refining story scope if iterations are high',
    });
  }

  if (config.model && !['sonnet', 'opus', 'haiku'].includes(config.model)) {
    errors.push({ field: 'model', message: `Invalid model: ${config.model}`, code: 'INVALID_MODEL' });
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Validate a feature
 */
export function validateFeature(feature: Partial<Feature>): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  if (!feature.id) {
    errors.push({ field: 'id', message: 'Feature ID is required', code: 'MISSING_ID' });
  } else if (!/^[a-z0-9-]+$/.test(feature.id)) {
    errors.push({ field: 'id', message: 'Feature ID must be lowercase alphanumeric with hyphens', code: 'INVALID_ID' });
  }

  if (!feature.title) {
    errors.push({ field: 'title', message: 'Feature title is required', code: 'MISSING_TITLE' });
  }

  if (!feature.stories || feature.stories.length === 0) {
    warnings.push({
      field: 'stories',
      message: 'Feature has no stories',
      suggestion: 'Run discovery or breakdown to generate stories',
    });
  } else {
    // Validate each story
    for (const story of feature.stories) {
      const storyResult = validateStory(story);
      errors.push(...storyResult.errors.map(e => ({ ...e, field: `stories.${story.id}.${e.field}` })));
      warnings.push(...storyResult.warnings.map(w => ({ ...w, field: `stories.${story.id}.${w.field}` })));
    }

    // Check for circular dependencies
    const deps = new Map<string, string[]>();
    for (const story of feature.stories) {
      deps.set(story.id, story.blockedBy || []);
    }
    const cycles = detectCycles(deps);
    if (cycles.length > 0) {
      errors.push({
        field: 'stories',
        message: `Circular dependencies detected: ${cycles.map(c => c.join(' → ')).join(', ')}`,
        code: 'CIRCULAR_DEPS',
      });
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Validate a story
 */
export function validateStory(story: Partial<Story>): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  if (!story.id) {
    errors.push({ field: 'id', message: 'Story ID is required', code: 'MISSING_ID' });
  }

  if (!story.title) {
    errors.push({ field: 'title', message: 'Story title is required', code: 'MISSING_TITLE' });
  } else if (story.title.length < 10) {
    warnings.push({
      field: 'title',
      message: 'Story title is very short',
      suggestion: 'Consider adding more detail for clarity',
    });
  }

  if (!story.scope || story.scope.length === 0) {
    warnings.push({
      field: 'scope',
      message: 'Story has no scope defined',
      suggestion: 'Define scope to guide implementation',
    });
  }

  if (story.status && !['pending', 'in_progress', 'complete', 'blocked', 'skipped'].includes(story.status)) {
    errors.push({ field: 'status', message: `Invalid status: ${story.status}`, code: 'INVALID_STATUS' });
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Detect cycles in dependencies
 */
function detectCycles(deps: Map<string, string[]>): string[][] {
  const cycles: string[][] = [];
  const visited = new Set<string>();
  const stack = new Set<string>();
  const path: string[] = [];

  function dfs(node: string): boolean {
    if (stack.has(node)) {
      const cycleStart = path.indexOf(node);
      cycles.push(path.slice(cycleStart).concat(node));
      return true;
    }
    if (visited.has(node)) return false;

    visited.add(node);
    stack.add(node);
    path.push(node);

    for (const dep of deps.get(node) || []) {
      dfs(dep);
    }

    stack.delete(node);
    path.pop();
    return false;
  }

  for (const node of deps.keys()) {
    if (!visited.has(node)) {
      dfs(node);
    }
  }

  return cycles;
}

/**
 * Format validation result for display
 */
export function formatValidationResult(result: ValidationResult): string {
  const lines: string[] = [];

  if (result.valid) {
    lines.push('✓ Validation passed');
  } else {
    lines.push('✗ Validation failed');
  }

  if (result.errors.length > 0) {
    lines.push('\nErrors:');
    for (const error of result.errors) {
      lines.push(`  ✗ ${error.field}: ${error.message}`);
    }
  }

  if (result.warnings.length > 0) {
    lines.push('\nWarnings:');
    for (const warning of result.warnings) {
      lines.push(`  ⚠ ${warning.field}: ${warning.message}`);
      if (warning.suggestion) {
        lines.push(`    → ${warning.suggestion}`);
      }
    }
  }

  return lines.join('\n');
}

/**
 * Validate and return result or throw
 */
export function assertValid<T>(
  value: T,
  validator: (v: T) => ValidationResult,
  entityName: string = 'configuration'
): T {
  const result = validator(value);
  if (!result.valid) {
    const errorMsg = result.errors.map(e => `${e.field}: ${e.message}`).join('; ');
    throw new Error(`Invalid ${entityName}: ${errorMsg}`);
  }
  return value;
}
