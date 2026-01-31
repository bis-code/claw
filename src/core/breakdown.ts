// Breakdown generation - create different approaches for feature implementation

import { ClaudeClient } from '../integrations/claude.js';
import { Story } from './feature.js';
import { Finding } from './discovery.js';
import { Repo } from './workspace.js';

export interface BreakdownApproach {
  name: string;
  description: string;
  recommended?: boolean;
  stories: ProposedStory[];
  estimatedHours: number;
  rationale: string;
}

export interface ProposedStory {
  title: string;
  scope: string[];
  repos: string[];
  estimatedHours: number;
  dependsOn?: string[];
}

export interface BreakdownContext {
  featureTitle: string;
  featureDescription: string;
  repos: Repo[];
  findings?: Finding[];
}

const BREAKDOWN_PROMPT = `You are analyzing a feature request to break it down into implementable stories.

Feature: {title}
Description: {description}

Available repos:
{repos}

{findings}

Generate exactly 3 different approaches to implement this feature:

1. **Risk-First** - Start with highest-risk integrations to validate early
2. **User-Journey** - Follow the user's path through the feature
3. **Repo-by-Repo** - Complete each repo before moving to the next

For each approach, output in this format:

APPROACH: <name>
DESCRIPTION: <one-line description>
RECOMMENDED: <yes|no>
RATIONALE: <why this approach>
ESTIMATED_HOURS: <total hours>

STORY: <title>
SCOPE: <comma-separated scope items>
REPOS: <comma-separated repo names>
HOURS: <estimated hours>
DEPENDS_ON: <comma-separated story titles or "none">

STORY: <next story...>

END_APPROACH

Repeat for all 3 approaches. Be specific and actionable.`;

export class BreakdownGenerator {
  private claude: ClaudeClient;

  constructor(workingDir: string) {
    this.claude = new ClaudeClient(workingDir);
  }

  /**
   * Generate breakdown approaches for a feature
   */
  async generateApproaches(context: BreakdownContext): Promise<BreakdownApproach[]> {
    const prompt = this.buildPrompt(context);

    const output = await this.claude.run(prompt, {
      model: 'sonnet',
      maxTurns: 5,
      timeoutMs: 180000, // 3 minutes
      dangerouslySkipPermissions: true,
    });

    return this.parseApproaches(output.rawOutput);
  }

  /**
   * Build the prompt with context
   */
  private buildPrompt(context: BreakdownContext): string {
    let prompt = BREAKDOWN_PROMPT
      .replace('{title}', context.featureTitle)
      .replace('{description}', context.featureDescription)
      .replace('{repos}', context.repos.map(r => `- ${r.name} (${r.type}, ${r.framework || 'unknown'})`).join('\n'));

    if (context.findings && context.findings.length > 0) {
      const findingsText = context.findings
        .slice(0, 10)
        .map(f => `- [${f.priority}] ${f.title}: ${f.description}`)
        .join('\n');
      prompt = prompt.replace('{findings}', `\nRelevant findings from discovery:\n${findingsText}`);
    } else {
      prompt = prompt.replace('{findings}', '');
    }

    return prompt;
  }

  /**
   * Parse approaches from Claude output
   */
  private parseApproaches(output: string): BreakdownApproach[] {
    const approaches: BreakdownApproach[] = [];
    const approachBlocks = output.split('END_APPROACH').filter(b => b.includes('APPROACH:'));

    for (const block of approachBlocks) {
      const approach = this.parseApproach(block);
      if (approach) {
        approaches.push(approach);
      }
    }

    // If parsing failed, create default approaches
    if (approaches.length === 0) {
      return this.createDefaultApproaches();
    }

    return approaches;
  }

  /**
   * Parse a single approach block
   */
  private parseApproach(block: string): BreakdownApproach | null {
    const lines = block.split('\n').map(l => l.trim()).filter(Boolean);

    let name = '';
    let description = '';
    let recommended = false;
    let rationale = '';
    let estimatedHours = 0;
    const stories: ProposedStory[] = [];

    let currentStory: Partial<ProposedStory> | null = null;

    for (const line of lines) {
      if (line.startsWith('APPROACH:')) {
        name = line.replace('APPROACH:', '').trim();
      } else if (line.startsWith('DESCRIPTION:')) {
        description = line.replace('DESCRIPTION:', '').trim();
      } else if (line.startsWith('RECOMMENDED:')) {
        recommended = line.toLowerCase().includes('yes');
      } else if (line.startsWith('RATIONALE:')) {
        rationale = line.replace('RATIONALE:', '').trim();
      } else if (line.startsWith('ESTIMATED_HOURS:')) {
        estimatedHours = parseInt(line.replace('ESTIMATED_HOURS:', '').trim(), 10) || 0;
      } else if (line.startsWith('STORY:')) {
        if (currentStory && currentStory.title) {
          stories.push(currentStory as ProposedStory);
        }
        currentStory = {
          title: line.replace('STORY:', '').trim(),
          scope: [],
          repos: [],
          estimatedHours: 2,
        };
      } else if (line.startsWith('SCOPE:') && currentStory) {
        currentStory.scope = line.replace('SCOPE:', '').split(',').map(s => s.trim()).filter(Boolean);
      } else if (line.startsWith('REPOS:') && currentStory) {
        currentStory.repos = line.replace('REPOS:', '').split(',').map(s => s.trim()).filter(Boolean);
      } else if (line.startsWith('HOURS:') && currentStory) {
        currentStory.estimatedHours = parseInt(line.replace('HOURS:', '').trim(), 10) || 2;
      } else if (line.startsWith('DEPENDS_ON:') && currentStory) {
        const deps = line.replace('DEPENDS_ON:', '').trim();
        if (deps.toLowerCase() !== 'none') {
          currentStory.dependsOn = deps.split(',').map(s => s.trim()).filter(Boolean);
        }
      }
    }

    // Add last story
    if (currentStory && currentStory.title) {
      stories.push(currentStory as ProposedStory);
    }

    if (!name || stories.length === 0) {
      return null;
    }

    return {
      name,
      description,
      recommended,
      stories,
      estimatedHours: estimatedHours || stories.reduce((sum, s) => sum + s.estimatedHours, 0),
      rationale,
    };
  }

  /**
   * Create default approaches if parsing fails
   */
  private createDefaultApproaches(): BreakdownApproach[] {
    return [
      {
        name: 'Single Story',
        description: 'Implement the entire feature as one story',
        recommended: true,
        stories: [{
          title: 'Implement feature',
          scope: ['Full implementation'],
          repos: [],
          estimatedHours: 4,
        }],
        estimatedHours: 4,
        rationale: 'Simple approach for straightforward features',
      },
    ];
  }

  /**
   * Create stories from a selected approach
   */
  approachToStories(approach: BreakdownApproach): Omit<Story, 'status'>[] {
    return approach.stories.map((s, i) => ({
      id: (i + 1).toString(),
      title: s.title,
      scope: s.scope,
      repos: s.repos,
      estimatedHours: s.estimatedHours,
      blockedBy: s.dependsOn?.map(dep => {
        const depIndex = approach.stories.findIndex(st => st.title === dep);
        return depIndex >= 0 ? (depIndex + 1).toString() : undefined;
      }).filter((d): d is string => d !== undefined),
    }));
  }
}

export { BREAKDOWN_PROMPT };
