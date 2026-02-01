// File converter - migrate existing markdown to claw feature format

import { readFile, readdir, mkdir, rename, writeFile } from 'fs/promises';
import { join, basename, dirname } from 'path';
import { existsSync } from 'fs';

export interface ConversionResult {
  sourceFile: string;
  featureId: string;
  title: string;
  stories: ConvertedStory[];
  completedItems: string[];
  deferredItems: string[];
  success: boolean;
  error?: string;
}

export interface ConvertedStory {
  id: string;
  title: string;
  status: 'pending' | 'complete';
  scope: string;
  priority?: string;
}

export interface ConversionOptions {
  /** Archive original file instead of deleting */
  archive?: boolean;
  /** Dry run - don't write files */
  dryRun?: boolean;
  /** Custom feature ID (default: derived from filename) */
  featureId?: string;
}

/**
 * Detect if a file looks like it could be converted to a feature
 */
export function isConvertible(content: string): boolean {
  // Look for patterns that indicate task lists or priority tables
  const patterns = [
    /\|\s*Item\s*\|\s*Status\s*\|/i,           // Priority table header
    /\|\s*#\s*\|\s*Story\s*\|/i,               // Story table
    /- \[[ x]\]/i,                              // Task list items
    /##\s*(P[0-3]|Priority|Tasks|Stories)/i,   // Priority headers
    /\|\s*⏳\s*Pending\s*\|/i,                 // Pending status
    /\|\s*✅\s*(DONE|Complete)\s*\|/i,         // Done status
  ];

  return patterns.some(p => p.test(content));
}

/**
 * Parse a markdown file and extract stories/tasks
 */
export function parseMarkdownToStories(content: string, filename: string): {
  title: string;
  stories: ConvertedStory[];
  completedItems: string[];
  deferredItems: string[];
} {
  const lines = content.split('\n');
  const stories: ConvertedStory[] = [];
  const completedItems: string[] = [];
  const deferredItems: string[] = [];

  // Extract title from first H1
  let title = basename(filename, '.md').replace(/-/g, ' ');
  const titleMatch = content.match(/^#\s+(.+)$/m);
  if (titleMatch) {
    title = titleMatch[1];
  }

  let storyId = 1;
  let currentSection = '';
  let isDeferred = false;

  for (const line of lines) {
    // Track section headers
    if (line.match(/^##\s+/)) {
      currentSection = line.toLowerCase();
      isDeferred = /deferred|future|v2|post-launch|at scale/i.test(currentSection);
    }

    // Parse table rows with status
    const tableMatch = line.match(/\|\s*([^|]+)\s*\|\s*(⏳\s*Pending|✅\s*(?:DONE|\*\*DONE\*\*)|Pending|Done|Complete)\s*\|/i);
    if (tableMatch) {
      const itemTitle = tableMatch[1].trim();
      const status = tableMatch[2].toLowerCase();
      const isDone = /done|complete|✅/.test(status);

      if (isDeferred) {
        deferredItems.push(itemTitle);
      } else if (isDone) {
        completedItems.push(itemTitle);
      } else {
        stories.push({
          id: String(storyId++),
          title: itemTitle,
          status: 'pending',
          scope: itemTitle,
          priority: extractPriority(currentSection),
        });
      }
      continue;
    }

    // Parse task list items: - [x] or - [ ]
    const taskMatch = line.match(/^[-*]\s+\[([ x])\]\s+(.+)$/i);
    if (taskMatch) {
      const isDone = taskMatch[1].toLowerCase() === 'x';
      const itemTitle = taskMatch[2].trim();

      if (isDeferred) {
        deferredItems.push(itemTitle);
      } else if (isDone) {
        completedItems.push(itemTitle);
      } else {
        stories.push({
          id: String(storyId++),
          title: itemTitle,
          status: 'pending',
          scope: itemTitle,
          priority: extractPriority(currentSection),
        });
      }
    }
  }

  return { title, stories, completedItems, deferredItems };
}

/**
 * Extract priority from section header
 */
function extractPriority(section: string): string | undefined {
  const match = section.match(/p([0-3])/i);
  return match ? `P${match[1]}` : undefined;
}

/**
 * Generate claw _overview.md content
 */
export function generateOverviewContent(
  featureId: string,
  title: string,
  description: string,
  stories: ConvertedStory[],
  completedItems: string[],
  deferredItems: string[]
): string {
  const now = new Date().toISOString();
  const pendingStories = stories.filter(s => s.status === 'pending');

  const storiesTable = pendingStories.map((s, i) => {
    const priority = s.priority ? ` [${s.priority}]` : '';
    return `| ${i + 1} | ${s.title}${priority} | ⏳ pending | - | ${s.scope} |`;
  }).join('\n');

  const completedSection = completedItems.length > 0
    ? `\n## Completed Items (Reference)\n\n${completedItems.map(i => `- [x] ${i}`).join('\n')}\n`
    : '';

  const deferredSection = deferredItems.length > 0
    ? `\n## Deferred Items (Future)\n\n${deferredItems.map(i => `- ${i}`).join('\n')}\n`
    : '';

  return `# Feature: ${title}

**ID:** ${featureId}
**Status:** active
**Created:** ${now}

## Description

${description}

## Stories

| # | Story | Status | Branch | Scope |
|---|-------|--------|--------|-------|
${storiesTable}

## Live Progress Tracker

| Metric | Value |
|--------|-------|
| Total Stories | ${pendingStories.length} |
| Completed | 0 |
| In Progress | 0 |
| Blocked | 0 |

**Current Story:** None
**Last Updated:** ${now}
${completedSection}${deferredSection}
## Session Log

| Date | Action | Details |
|------|--------|---------|
| ${now.split('T')[0]} | Converted | Migrated from existing markdown to claw format |

---

*Managed by claw*
`;
}

/**
 * Convert a markdown file to claw feature format
 */
export async function convertFile(
  sourcePath: string,
  featuresDir: string,
  options: ConversionOptions = {}
): Promise<ConversionResult> {
  try {
    const content = await readFile(sourcePath, 'utf-8');
    const filename = basename(sourcePath);

    // Generate feature ID from filename or options
    const featureId = options.featureId ||
      basename(filename, '.md')
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '');

    // Parse the content
    const { title, stories, completedItems, deferredItems } = parseMarkdownToStories(content, filename);

    if (stories.length === 0 && completedItems.length === 0) {
      return {
        sourceFile: sourcePath,
        featureId,
        title,
        stories: [],
        completedItems: [],
        deferredItems: [],
        success: false,
        error: 'No actionable items found in file',
      };
    }

    // Generate overview content
    const overviewContent = generateOverviewContent(
      featureId,
      title,
      `Converted from ${filename}`,
      stories,
      completedItems,
      deferredItems
    );

    if (!options.dryRun) {
      // Create feature directory
      const featureDir = join(featuresDir, featureId);
      if (!existsSync(featureDir)) {
        await mkdir(featureDir, { recursive: true });
      }

      // Write _overview.md
      await writeFile(join(featureDir, '_overview.md'), overviewContent);

      // Archive or leave original
      if (options.archive) {
        const archiveName = `_archive-${filename}`;
        await rename(sourcePath, join(dirname(sourcePath), archiveName));
      }
    }

    return {
      sourceFile: sourcePath,
      featureId,
      title,
      stories,
      completedItems,
      deferredItems,
      success: true,
    };
  } catch (error) {
    return {
      sourceFile: sourcePath,
      featureId: '',
      title: '',
      stories: [],
      completedItems: [],
      deferredItems: [],
      success: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

/**
 * Scan a directory for convertible files
 */
export async function scanForConvertible(dirPath: string): Promise<string[]> {
  const convertible: string[] = [];

  try {
    const entries = await readdir(dirPath, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.isFile() && entry.name.endsWith('.md') && !entry.name.startsWith('_')) {
        const filePath = join(dirPath, entry.name);
        const content = await readFile(filePath, 'utf-8');

        if (isConvertible(content)) {
          convertible.push(filePath);
        }
      } else if (entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'features') {
        // Recurse into subdirectories
        const subFiles = await scanForConvertible(join(dirPath, entry.name));
        convertible.push(...subFiles);
      }
    }
  } catch {
    // Ignore errors reading directories
  }

  return convertible;
}
