// Claw v2 - Orchestration layer for autonomous AI development
// Main exports for programmatic usage

// Core modules
export { Workspace, type WorkspaceConfig, type Repo, type RepoRelationship } from './core/workspace.js';
export { FeatureManager, type Feature, type Story, type StoryStatus, type BreakdownOption } from './core/feature.js';
export { SessionRunner, type SessionConfig, type SessionResult, type SessionState } from './core/session.js';
export { DiscoveryEngine, type DiscoveryResult, type Finding, type DiscoveryMode, type DiscoveryOptions } from './core/discovery.js';
export { BreakdownGenerator, type BreakdownApproach, type ProposedStory, type BreakdownContext } from './core/breakdown.js';
export { StoryRefiner, type RefinementAction, type RefinementResult } from './core/refinement.js';
export { DependencyManager, type DependencyNode, type DependencyGraph } from './core/dependencies.js';

// Integrations
export { ObsidianClient, type ObsidianNote } from './integrations/obsidian.js';
export { GitHubClient, type GitHubIssue, type GitHubPR } from './integrations/github.js';
export { ClaudeClient, type ClaudeSession, type ClaudeOutput, CLAW_MARKERS } from './integrations/claude.js';
