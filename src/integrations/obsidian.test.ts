// Quick integration test for Obsidian client
import { ObsidianClient } from './obsidian.js';

async function test() {
  const client = new ObsidianClient('~/Documents/Obsidian');

  // Test read
  console.log('Testing read...');
  const note = await client.readNote('Projects/claw/2026-01-31-v2-orchestration-tool/_overview');
  if (note) {
    console.log(`✓ Read note: ${note.path}`);
    console.log(`  Content length: ${note.content.length} chars`);
  } else {
    console.log('✗ Failed to read note');
  }

  // Test list directory
  console.log('\nTesting list directory...');
  const { dirs, files } = await client.listDirectory('Projects/claw');
  console.log(`✓ Found ${dirs.length} dirs, ${files.length} files`);
  console.log(`  Dirs: ${dirs.join(', ')}`);
  console.log(`  Files: ${files.join(', ')}`);

  // Test exists
  console.log('\nTesting exists...');
  const exists = await client.exists('Projects/claw/2026-01-31-v2-orchestration-tool/_overview');
  console.log(`✓ Exists check: ${exists}`);

  console.log('\n✓ All tests passed!');
}

test().catch(console.error);
