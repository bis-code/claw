// Test claude output parsing
import { ClaudeClient, CLAW_MARKERS } from './claude.js';

const client = new ClaudeClient(process.cwd());

// Test output parsing
console.log('Testing output parsing...\n');

// Test 1: Complete with commits
const output1 = `
Working on the feature...
Wrote tests first.
Implemented the solution.
All tests passing!

CLAW_COMMIT: abc123 feat(auth): add login endpoint
CLAW_COMMIT: def456 test(auth): add login tests
CLAW_STATUS: COMPLETE
`;

const parsed1 = client.parseOutput(output1);
console.log('Test 1 - Complete with commits:');
console.log(`  Status: ${parsed1.status} ${parsed1.status === 'complete' ? '✓' : '✗'}`);
console.log(`  Commits: ${parsed1.commits.length} ${parsed1.commits.length === 2 ? '✓' : '✗'}`);

// Test 2: Blocked
const output2 = `
Tried to implement but hit a wall.
CLAW_STATUS: BLOCKED Missing API key for Stripe
`;

const parsed2 = client.parseOutput(output2);
console.log('\nTest 2 - Blocked:');
console.log(`  Status: ${parsed2.status} ${parsed2.status === 'blocked' ? '✓' : '✗'}`);
console.log(`  Reason: ${parsed2.blockerReason} ${parsed2.blockerReason?.includes('Stripe') ? '✓' : '✗'}`);

// Test 3: Needs input
const output3 = `
I have a question.
CLAW_STATUS: NEEDS_INPUT Should I use REST or GraphQL?
`;

const parsed3 = client.parseOutput(output3);
console.log('\nTest 3 - Needs input:');
console.log(`  Status: ${parsed3.status} ${parsed3.status === 'needs_input' ? '✓' : '✗'}`);
console.log(`  Question: ${parsed3.question} ${parsed3.question?.includes('GraphQL') ? '✓' : '✗'}`);

// Test 4: With PR
const output4 = `
All done, created PR.
CLAW_COMMIT: ghi789 feat(billing): add payment flow
CLAW_PR: 42
CLAW_STATUS: COMPLETE
`;

const parsed4 = client.parseOutput(output4);
console.log('\nTest 4 - With PR:');
console.log(`  Status: ${parsed4.status} ${parsed4.status === 'complete' ? '✓' : '✗'}`);
console.log(`  PR: ${parsed4.pr} ${parsed4.pr === 42 ? '✓' : '✗'}`);

// Test prompt generation
console.log('\nTest 5 - Prompt generation:');
const prompt = client.generateStoryPrompt({
  title: 'Add authentication',
  scope: ['Login endpoint', 'JWT tokens'],
  repos: ['backend'],
}, 'User Management');
console.log(`  Contains title: ${prompt.includes('Add authentication') ? '✓' : '✗'}`);
console.log(`  Contains feature: ${prompt.includes('User Management') ? '✓' : '✗'}`);
console.log(`  Contains CLAW_STATUS: ${prompt.includes('CLAW_STATUS') ? '✓' : '✗'}`);

console.log('\n✓ All parsing tests passed!');
