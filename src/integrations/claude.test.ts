// Test claude output parsing
import { ClaudeClient } from './claude.js';

describe('ClaudeClient', () => {
  let client: ClaudeClient;

  beforeAll(() => {
    client = new ClaudeClient(process.cwd());
  });

  describe('parseOutput', () => {
    it('should parse complete status with commits', () => {
      const output = `
Working on the feature...
Wrote tests first.
Implemented the solution.
All tests passing!

CLAW_COMMIT: abc123 feat(auth): add login endpoint
CLAW_COMMIT: def456 test(auth): add login tests
CLAW_STATUS: COMPLETE
`;

      const parsed = client.parseOutput(output);
      expect(parsed.status).toBe('complete');
      expect(parsed.commits).toHaveLength(2);
      expect(parsed.commits[0]).toBe('abc123 feat(auth): add login endpoint');
      expect(parsed.commits[1]).toBe('def456 test(auth): add login tests');
    });

    it('should parse blocked status with reason', () => {
      const output = `
Tried to implement but hit a wall.
CLAW_STATUS: BLOCKED Missing API key for Stripe
`;

      const parsed = client.parseOutput(output);
      expect(parsed.status).toBe('blocked');
      expect(parsed.blockerReason).toContain('Stripe');
    });

    it('should parse needs_input status with question', () => {
      const output = `
I have a question.
CLAW_STATUS: NEEDS_INPUT Should I use REST or GraphQL?
`;

      const parsed = client.parseOutput(output);
      expect(parsed.status).toBe('needs_input');
      expect(parsed.question).toContain('GraphQL');
    });

    it('should parse PR number', () => {
      const output = `
All done, created PR.
CLAW_COMMIT: ghi789 feat(billing): add payment flow
CLAW_PR: 42
CLAW_STATUS: COMPLETE
`;

      const parsed = client.parseOutput(output);
      expect(parsed.status).toBe('complete');
      expect(parsed.pr).toBe(42);
      expect(parsed.commits).toHaveLength(1);
    });
  });

  describe('generateStoryPrompt', () => {
    it('should generate prompt with story details', () => {
      const prompt = client.generateStoryPrompt({
        title: 'Add authentication',
        scope: ['Login endpoint', 'JWT tokens'],
        repos: ['backend'],
      }, 'User Management');

      expect(prompt).toContain('Add authentication');
      expect(prompt).toContain('User Management');
      expect(prompt).toContain('CLAW_STATUS');
      expect(prompt).toContain('Login endpoint');
      expect(prompt).toContain('JWT tokens');
    });
  });
});
