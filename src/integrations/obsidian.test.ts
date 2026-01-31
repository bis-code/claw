// Test Obsidian client
import { ObsidianClient } from './obsidian.js';
import fs from 'fs/promises';
import path from 'path';
import os from 'os';

describe('ObsidianClient', () => {
  let client: ObsidianClient;
  let testDir: string;

  beforeAll(async () => {
    // Create a temporary test directory
    testDir = path.join(os.tmpdir(), `obsidian-test-${Date.now()}`);
    await fs.mkdir(testDir, { recursive: true });
    client = new ObsidianClient(testDir);
  });

  afterAll(async () => {
    // Clean up test directory
    try {
      await fs.rm(testDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe('writeNote and readNote', () => {
    it('should write and read a note', async () => {
      const notePath = 'test/write-read-test';
      const content = '# Test Note\n\nSome content here';

      await client.writeNote(notePath, content);
      const note = await client.readNote(notePath);

      expect(note).not.toBeNull();
      expect(note?.content).toBe(content);
      expect(note?.path).toBe(notePath);
    });

    it('should return null for non-existent note', async () => {
      const note = await client.readNote('nonexistent/note');
      expect(note).toBeNull();
    });
  });

  describe('exists', () => {
    it('should return true for existing note', async () => {
      const notePath = 'test/exists-test';
      await client.writeNote(notePath, 'content');

      const exists = await client.exists(notePath);
      expect(exists).toBe(true);
    });

    it('should return false for non-existent note', async () => {
      const exists = await client.exists('nonexistent/note-xyz');
      expect(exists).toBe(false);
    });
  });

  describe('listDirectory', () => {
    beforeAll(async () => {
      // Create test structure
      await client.writeNote('listtest/note1', 'content 1');
      await client.writeNote('listtest/note2', 'content 2');
      await client.writeNote('listtest/subdir/note3', 'content 3');
    });

    it('should list files and directories', async () => {
      const result = await client.listDirectory('listtest');

      expect(result.files).toContain('note1.md');
      expect(result.files).toContain('note2.md');
      expect(result.dirs).toContain('subdir');
    });
  });

  describe('patchNote', () => {
    it('should replace text in a note', async () => {
      const notePath = 'test/patch-test';
      await client.writeNote(notePath, '# Title\n\nOld text here\n\nMore content');

      await client.patchNote(notePath, 'Old text here', 'New text here');

      const note = await client.readNote(notePath);
      expect(note?.content).toBe('# Title\n\nNew text here\n\nMore content');
    });

    it('should return false if old text not found', async () => {
      const notePath = 'test/patch-fail-test';
      await client.writeNote(notePath, '# Title\n\nSome content');

      const result = await client.patchNote(notePath, 'Not found text', 'New text');
      expect(result).toBe(false);
    });
  });

  describe('appendToNote', () => {
    it('should append content to existing note', async () => {
      const notePath = 'test/append-test';
      await client.writeNote(notePath, 'Line 1');

      await client.appendToNote(notePath, '\nLine 2');

      const note = await client.readNote(notePath);
      expect(note?.content).toBe('Line 1\nLine 2');
    });
  });

  describe('deleteNote', () => {
    it('should delete an existing note', async () => {
      const notePath = 'test/delete-test';
      await client.writeNote(notePath, 'to delete');

      await client.deleteNote(notePath);

      const exists = await client.exists(notePath);
      expect(exists).toBe(false);
    });
  });
});
