// Claw v2 - Orchestration layer for autonomous AI development
// Main exports for programmatic usage

// Core modules
export { Workspace, type WorkspaceConfig, type Repo, type RepoRelationship, type RepoContext, type CrossRepoContext, type MultiRepoCommit } from './core/workspace.js';
export { FeatureManager, type Feature, type Story, type StoryStatus, type BreakdownOption } from './core/feature.js';
export { SessionRunner, type SessionConfig, type SessionResult, type SessionState } from './core/session.js';
export { DiscoveryEngine, type DiscoveryResult, type Finding, type DiscoveryMode, type DiscoveryOptions } from './core/discovery.js';
export { BreakdownGenerator, type BreakdownApproach, type ProposedStory, type BreakdownContext } from './core/breakdown.js';
export { StoryRefiner, type RefinementAction, type RefinementResult } from './core/refinement.js';
export { DependencyManager, type DependencyNode, type DependencyGraph } from './core/dependencies.js';
export { IterationEngine, type IterationConfig, type IterationState, type IterationResult, type StuckAnalysis } from './core/iteration.js';
export { CheckpointManager, type CheckpointData } from './core/checkpoint.js';
export { HotkeyManager, type HotkeyAction, type HotkeyHandler, type HotkeyManagerOptions, createHotkeyAwareSpinner } from './core/hotkeys.js';
export { ProgressReporter, createSpinner, type ProgressEvent, type ProgressStats, type ProgressCallback } from './core/progress.js';
export {
  validateWorkspaceConfig,
  validateSessionConfig,
  validateFeature,
  validateStory,
  formatValidationResult,
  assertValid,
  type ValidationResult,
  type ValidationError,
  type ValidationWarning,
} from './core/validation.js';

// Integrations
export { ObsidianClient, type ObsidianNote } from './integrations/obsidian.js';
export { GitHubClient, type GitHubIssue, type GitHubPR } from './integrations/github.js';
export { ClaudeClient, type ClaudeSession, type ClaudeOutput, CLAW_MARKERS } from './integrations/claude.js';
