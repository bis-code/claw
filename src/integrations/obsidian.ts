// Obsidian integration via MCP

export interface ObsidianNote {
  path: string;
  content: string;
  frontmatter?: Record<string, any>;
}

export class ObsidianClient {
  constructor(private vaultPath: string) {}

  async readNote(path: string): Promise<ObsidianNote | null> {
    // TODO: Read note via MCP or direct file access (Story 1.3)
    throw new Error('Not implemented - Story 1.3');
  }

  async writeNote(path: string, content: string, frontmatter?: Record<string, any>): Promise<void> {
    // TODO: Write note via MCP (Story 1.3)
    throw new Error('Not implemented - Story 1.3');
  }

  async patchNote(path: string, oldString: string, newString: string): Promise<void> {
    // TODO: Patch note via MCP (Story 1.3)
    throw new Error('Not implemented - Story 1.3');
  }

  async listDirectory(path: string): Promise<{ dirs: string[]; files: string[] }> {
    // TODO: List directory via MCP (Story 1.3)
    throw new Error('Not implemented - Story 1.3');
  }

  async searchNotes(query: string): Promise<ObsidianNote[]> {
    // TODO: Search notes via MCP (Story 1.3)
    throw new Error('Not implemented - Story 1.3');
  }

  // Helper methods for feature/session tracking
  async updateProgressTracker(sessionPath: string, updates: Record<string, string>): Promise<void> {
    // TODO: Update live progress tracker table (Story 3.4)
    throw new Error('Not implemented - Story 3.4');
  }

  async appendSessionLog(sessionPath: string, entry: { date: string; action: string; details: string }): Promise<void> {
    // TODO: Append to session log table (Story 3.4)
    throw new Error('Not implemented - Story 3.4');
  }
}
