// Discovery agents - scan codebase to find work

import { ClaudeClient, ClaudeOutput } from '../integrations/claude.js';
import { Repo } from './workspace.js';

export interface DiscoveryResult {
  agent: string;
  findings: Finding[];
  tokensUsed?: number;
  duration?: number;
}

export interface Finding {
  type: 'todo' | 'test-gap' | 'security' | 'code-quality' | 'dependency';
  title: string;
  description: string;
  file?: string;
  line?: number;
  priority: 'P0' | 'P1' | 'P2' | 'P3';
  estimatedHours?: number;
}

export type DiscoveryMode = 'shallow' | 'balanced' | 'deep';

export interface DiscoveryOptions {
  mode: DiscoveryMode;
  focus?: string;
  repos: Repo[];
  maxFindings?: number;
}

// Agent prompts for different discovery types
const AGENT_PROMPTS = {
  todo: `Scan this codebase for TODO, FIXME, HACK, and XXX comments.
For each significant one, output in this format:
FINDING: TODO | <title> | <file>:<line> | <priority P0-P3> | <description>

Only report significant TODOs that represent real work, not trivial notes.
Limit to 10 most important findings.`,

  testGap: `Analyze test coverage gaps in this codebase.
Look for:
- Files without corresponding test files
- Functions/classes without tests
- Critical paths without E2E coverage

For each gap, output:
FINDING: TEST_GAP | <title> | <file> | <priority P0-P3> | <description>

Focus on high-value gaps. Limit to 10 findings.`,

  security: `Scan for potential security issues:
- Hardcoded secrets or API keys
- SQL injection risks
- XSS vulnerabilities
- Missing authentication/authorization
- Insecure dependencies

For each issue, output:
FINDING: SECURITY | <title> | <file>:<line> | <priority P0-P3> | <description>

Be conservative - only report real issues. Limit to 10 findings.`,

  codeQuality: `Analyze code quality issues:
- Functions over 50 lines
- Duplicate code blocks
- Inconsistent patterns
- Missing error handling
- Complex cyclomatic complexity

For each issue, output:
FINDING: CODE_QUALITY | <title> | <file>:<line> | <priority P0-P3> | <description>

Focus on impactful issues. Limit to 10 findings.`,

  dependency: `Check for dependency issues:
- Run npm outdated or equivalent
- Look for deprecated packages
- Security vulnerabilities in deps

For each issue, output:
FINDING: DEPENDENCY | <title> | <package> | <priority P0-P3> | <description>

Limit to 10 findings.`,
};

export class DiscoveryEngine {
  private claude: ClaudeClient;

  constructor(workingDir: string) {
    this.claude = new ClaudeClient(workingDir);
  }

  /**
   * Run all discovery agents in parallel
   */
  async runDiscovery(options: DiscoveryOptions): Promise<DiscoveryResult[]> {
    const { mode, focus } = options;

    // Determine which agents to run based on mode
    const agents = this.getAgentsForMode(mode);

    // Run agents in parallel
    const promises = agents.map(agent => this.runAgent(agent, options));
    const results = await Promise.all(promises);

    return results;
  }

  /**
   * Get agents to run based on discovery mode
   */
  private getAgentsForMode(mode: DiscoveryMode): (keyof typeof AGENT_PROMPTS)[] {
    switch (mode) {
      case 'shallow':
        return ['todo', 'testGap'];
      case 'balanced':
        return ['todo', 'testGap', 'security', 'codeQuality'];
      case 'deep':
        return ['todo', 'testGap', 'security', 'codeQuality', 'dependency'];
    }
  }

  /**
   * Run a single discovery agent
   */
  private async runAgent(
    agent: keyof typeof AGENT_PROMPTS,
    options: DiscoveryOptions
  ): Promise<DiscoveryResult> {
    const startTime = Date.now();
    const prompt = this.buildAgentPrompt(agent, options);

    const model = this.getModelForAgent(agent, options.mode);
    const maxTurns = this.getMaxTurnsForMode(options.mode);

    try {
      const output = await this.claude.run(prompt, {
        model,
        maxTurns,
        timeoutMs: 120000, // 2 minute timeout per agent
        dangerouslySkipPermissions: true,
      });

      const findings = this.parseFindings(output.rawOutput, agent);

      return {
        agent,
        findings: findings.slice(0, options.maxFindings || 10),
        duration: Date.now() - startTime,
      };
    } catch (error) {
      return {
        agent,
        findings: [],
        duration: Date.now() - startTime,
      };
    }
  }

  /**
   * Build prompt for an agent
   */
  private buildAgentPrompt(agent: keyof typeof AGENT_PROMPTS, options: DiscoveryOptions): string {
    let prompt = AGENT_PROMPTS[agent];

    if (options.focus) {
      prompt += `\n\nFocus on: ${options.focus}`;
    }

    if (options.repos.length > 0) {
      prompt += `\n\nRepos to scan:\n${options.repos.map(r => `- ${r.name} (${r.type})`).join('\n')}`;
    }

    return prompt;
  }

  /**
   * Get model for agent based on mode
   */
  private getModelForAgent(agent: keyof typeof AGENT_PROMPTS, mode: DiscoveryMode): 'haiku' | 'sonnet' {
    if (mode === 'deep') {
      return 'sonnet';
    }

    // Mechanical tasks use haiku, reasoning tasks use sonnet
    const haikuAgents = ['todo', 'testGap', 'dependency'];
    return haikuAgents.includes(agent) ? 'haiku' : 'sonnet';
  }

  /**
   * Get max turns for mode
   */
  private getMaxTurnsForMode(mode: DiscoveryMode): number {
    switch (mode) {
      case 'shallow': return 3;
      case 'balanced': return 5;
      case 'deep': return 10;
    }
  }

  /**
   * Parse findings from agent output
   */
  private parseFindings(output: string, agent: keyof typeof AGENT_PROMPTS): Finding[] {
    const findings: Finding[] = [];
    const lines = output.split('\n');

    for (const line of lines) {
      if (!line.startsWith('FINDING:')) continue;

      const parts = line.replace('FINDING:', '').split('|').map(p => p.trim());
      if (parts.length < 5) continue;

      const [type, title, location, priority, description] = parts;

      // Parse file:line from location
      let file: string | undefined;
      let lineNum: number | undefined;
      if (location?.includes(':')) {
        const [f, l] = location.split(':');
        file = f;
        lineNum = parseInt(l, 10);
      } else {
        file = location;
      }

      findings.push({
        type: this.mapFindingType(type),
        title,
        description,
        file,
        line: lineNum,
        priority: this.validatePriority(priority),
      });
    }

    return findings;
  }

  /**
   * Map finding type string to enum
   */
  private mapFindingType(type: string): Finding['type'] {
    const map: Record<string, Finding['type']> = {
      'TODO': 'todo',
      'TEST_GAP': 'test-gap',
      'SECURITY': 'security',
      'CODE_QUALITY': 'code-quality',
      'DEPENDENCY': 'dependency',
    };
    return map[type] || 'todo';
  }

  /**
   * Validate priority
   */
  private validatePriority(priority: string): Finding['priority'] {
    const valid = ['P0', 'P1', 'P2', 'P3'];
    return valid.includes(priority) ? priority as Finding['priority'] : 'P2';
  }

  /**
   * Convert findings to stories
   */
  findingsToStories(findings: Finding[]): { title: string; scope: string[]; priority: string }[] {
    return findings.map(f => ({
      title: f.title,
      scope: [f.description, f.file ? `File: ${f.file}${f.line ? `:${f.line}` : ''}` : ''].filter(Boolean),
      priority: f.priority,
    }));
  }
}

export { AGENT_PROMPTS };
