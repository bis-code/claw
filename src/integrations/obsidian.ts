// Obsidian integration via direct file access
// Obsidian watches the filesystem, so direct read/write works

import { readFile, writeFile, readdir, mkdir, stat } from 'fs/promises';
import { join, dirname } from 'path';
import { existsSync } from 'fs';
import { homedir } from 'os';

export interface ObsidianNote {
  path: string;
  content: string;
  frontmatter?: Record<string, any>;
}

export interface FrontMatter {
  [key: string]: any;
}

export class ObsidianClient {
  private vaultPath: string;

  constructor(vaultPath: string) {
    // Expand ~ to home directory
    this.vaultPath = vaultPath.replace(/^~/, homedir());
  }

  /**
   * Get full path for a note
   */
  private getFullPath(notePath: string): string {
    // Ensure .md extension
    const path = notePath.endsWith('.md') ? notePath : `${notePath}.md`;
    return join(this.vaultPath, path);
  }

  /**
   * Parse frontmatter from content
   */
  private parseFrontmatter(content: string): { frontmatter?: FrontMatter; body: string } {
    const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
    if (!match) {
      return { body: content };
    }

    try {
      // Simple YAML parsing (key: value format)
      const frontmatter: FrontMatter = {};
      const lines = match[1].split('\n');
      for (const line of lines) {
        const colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          const key = line.slice(0, colonIndex).trim();
          const value = line.slice(colonIndex + 1).trim();
          frontmatter[key] = value;
        }
      }
      return { frontmatter, body: match[2] };
    } catch {
      return { body: content };
    }
  }

  /**
   * Format frontmatter to string
   */
  private formatFrontmatter(fm: FrontMatter): string {
    const lines = Object.entries(fm).map(([k, v]) => `${k}: ${v}`);
    return `---\n${lines.join('\n')}\n---\n`;
  }

  /**
   * Read a note from the vault
   */
  async readNote(path: string): Promise<ObsidianNote | null> {
    const fullPath = this.getFullPath(path);

    if (!existsSync(fullPath)) {
      return null;
    }

    try {
      const content = await readFile(fullPath, 'utf-8');
      const { frontmatter, body } = this.parseFrontmatter(content);

      return {
        path,
        content: body,
        frontmatter,
      };
    } catch (e) {
      return null;
    }
  }

  /**
   * Write a note to the vault
   */
  async writeNote(path: string, content: string, frontmatter?: FrontMatter): Promise<void> {
    const fullPath = this.getFullPath(path);

    // Ensure directory exists
    const dir = dirname(fullPath);
    if (!existsSync(dir)) {
      await mkdir(dir, { recursive: true });
    }

    // Build full content
    let fullContent = content;
    if (frontmatter && Object.keys(frontmatter).length > 0) {
      fullContent = this.formatFrontmatter(frontmatter) + content;
    }

    await writeFile(fullPath, fullContent);
  }

  /**
   * Patch a note by replacing a string
   */
  async patchNote(path: string, oldString: string, newString: string, replaceAll: boolean = false): Promise<boolean> {
    const note = await this.readNote(path);
    if (!note) {
      return false;
    }

    // Reconstruct full content with frontmatter
    let fullContent = note.frontmatter
      ? this.formatFrontmatter(note.frontmatter) + note.content
      : note.content;

    // Check if oldString exists
    if (!fullContent.includes(oldString)) {
      return false;
    }

    // Replace
    const newContent = replaceAll
      ? fullContent.split(oldString).join(newString)
      : fullContent.replace(oldString, newString);

    await writeFile(this.getFullPath(path), newContent);
    return true;
  }

  /**
   * List directory contents
   */
  async listDirectory(path: string): Promise<{ dirs: string[]; files: string[] }> {
    const fullPath = join(this.vaultPath, path);

    if (!existsSync(fullPath)) {
      return { dirs: [], files: [] };
    }

    const entries = await readdir(fullPath, { withFileTypes: true });
    const dirs: string[] = [];
    const files: string[] = [];

    for (const entry of entries) {
      if (entry.name.startsWith('.')) continue;

      if (entry.isDirectory()) {
        dirs.push(entry.name);
      } else if (entry.name.endsWith('.md')) {
        files.push(entry.name);
      }
    }

    return { dirs, files };
  }

  /**
   * Check if a note exists
   */
  async exists(path: string): Promise<boolean> {
    return existsSync(this.getFullPath(path));
  }

  /**
   * Create a directory
   */
  async createDirectory(path: string): Promise<void> {
    const fullPath = join(this.vaultPath, path);
    if (!existsSync(fullPath)) {
      await mkdir(fullPath, { recursive: true });
    }
  }

  /**
   * Update a progress tracker table row
   */
  async updateProgressTracker(sessionPath: string, storyId: string, status: string, additionalUpdates?: Record<string, string>): Promise<boolean> {
    const note = await this.readNote(sessionPath);
    if (!note) return false;

    // Find the row with this story ID and update its status
    const pattern = new RegExp(`(\\| ${storyId} \\|[^|]*\\|) [^|]* (\\|)`, 'g');
    const newContent = note.content.replace(pattern, `$1 ${status} $2`);

    if (newContent === note.content) {
      return false; // No change made
    }

    await this.writeNote(sessionPath, newContent, note.frontmatter);
    return true;
  }

  /**
   * Append to session log table
   */
  async appendSessionLog(sessionPath: string, entry: { date: string; action: string; details: string }): Promise<boolean> {
    const note = await this.readNote(sessionPath);
    if (!note) return false;

    // Find the session log table and append a row
    const logPattern = /(\| Date \| Action \| Details \|[\s\S]*?)(\n\n---|\n\n\*|$)/;
    const match = note.content.match(logPattern);

    if (!match) return false;

    const newRow = `| ${entry.date} | ${entry.action} | ${entry.details} |\n`;
    const newContent = note.content.replace(logPattern, `$1${newRow}$2`);

    await this.writeNote(sessionPath, newContent, note.frontmatter);
    return true;
  }

  /**
   * Get vault path
   */
  getVaultPath(): string {
    return this.vaultPath;
  }

  /**
   * Append content to an existing note
   */
  async appendToNote(path: string, content: string): Promise<void> {
    const note = await this.readNote(path);
    if (!note) {
      throw new Error(`Note not found: ${path}`);
    }

    const newContent = note.content + content;
    await this.writeNote(path, newContent, note.frontmatter);
  }

  /**
   * Delete a note from the vault
   */
  async deleteNote(path: string): Promise<void> {
    const fullPath = this.getFullPath(path);
    const { unlink } = await import('fs/promises');
    await unlink(fullPath);
  }
}
