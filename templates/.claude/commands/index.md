# /index - Generate Project Index

Generate a project index file for faster navigation.

## Usage
- `/index` - Generate index for current project
- `/index --update` - Update existing index
- `/index --show` - Show current index
- `/index --multi` - For multi-repo projects (create index in each sub-repo)
- `/index --mono` - For monorepos (single index with package mapping)

## Options

- None (default) - Auto-detect project type and generate index
- `--update` - Regenerate existing index
- `--show` - Display current index contents
- `--multi` - Force multi-repo mode (index each sub-repo)
- `--mono` - Force monorepo mode (single index with packages)

## Project Types

### Multi-Repo (e.g., game project)
```
game/
├── deployments/.claude/project-index.json
├── web3-backend/.claude/project-index.json
├── frontend/.claude/project-index.json
└── game/.claude/project-index.json
```
Each repo has its own index. Run `/index` in each sub-repo.

### Monorepo (e.g., processing-videos)
```
processing-videos/
├── .claude/project-index.json  # Root index with packages
├── packages/api/
├── packages/worker/
└── packages/shared/
```
Single index maps all packages/workspaces.

## What It Does

Creates `.claude/project-index.json` containing:
1. Project structure overview
2. Key entry points
3. Important files and their purposes
4. Directory purposes
5. (Monorepo) Package/workspace mapping
6. (Multi-repo) Cross-repo dependencies

## Instructions

### 1. Analyze Project Structure
Use Glob to find key files:
```
**/package.json, **/Cargo.toml, **/go.mod, **/requirements.txt
**/src/index.*, **/src/main.*, **/src/app.*
**/README.md, **/CLAUDE.md
```

### 2. Identify Entry Points
Look for:
- Main files (index.ts, main.py, main.go)
- Config files (*.config.*, settings.*)
- API routes (routes/, api/, handlers/)
- Components (components/, views/, pages/)

### 3. Generate Index
Create `.claude/project-index.json`:
```json
{
  "name": "project-name",
  "type": "typescript|python|go|rust|...",
  "structure": {
    "src": "Source code",
    "tests": "Test files",
    "docs": "Documentation"
  },
  "entryPoints": {
    "src/index.ts": "Main entry point",
    "src/api/routes.ts": "API routes"
  },
  "keyFiles": [
    {"path": "src/config.ts", "purpose": "Configuration"},
    {"path": "src/types.ts", "purpose": "Type definitions"}
  ]
}
```

### 4. Save Index
Write to `.claude/project-index.json`
Add to .gitignore if not present

## Multi-Repo Index (--multi)

For projects with multiple git repos (like game/):

1. Identify all sub-repos (directories with .git)
2. Generate index for EACH sub-repo
3. Create root index with repo references:

```json
{
  "name": "game-project",
  "type": "multi-repo",
  "repos": {
    "deployments": {"path": "deployments/", "type": "hardhat", "purpose": "Deployment configs"},
    "web3-backend": {"path": "web3-backend/", "type": "dotnet-hardhat", "purpose": "C# API + Solidity"},
    "game": {"path": "game/", "type": "unity", "purpose": "Unity game client"},
    "frontend": {"path": "frontend/", "type": "react", "purpose": "Web dashboard"}
  },
  "crossRepoDeps": {
    "frontend → web3-backend": "API calls",
    "game → web3-backend": "Smart contract interactions",
    "deployments → all": "Docker orchestration"
  }
}
```

## Monorepo Index (--mono)

For monorepos with workspaces/packages:

1. Find workspace config (package.json workspaces, pnpm-workspace.yaml, etc.)
2. Map all packages with their purposes
3. Create single comprehensive index:

```json
{
  "name": "processing-videos",
  "type": "monorepo",
  "workspaceConfig": "pnpm-workspace.yaml",
  "packages": {
    "@pv/api": {"path": "packages/api/", "purpose": "REST API", "entry": "src/index.ts"},
    "@pv/worker": {"path": "packages/worker/", "purpose": "Video processing", "entry": "src/main.ts"},
    "@pv/shared": {"path": "packages/shared/", "purpose": "Shared utilities", "entry": "src/index.ts"}
  },
  "sharedDeps": ["@pv/shared"],
  "entryPoints": {
    "packages/api/src/index.ts": "API server entry",
    "packages/worker/src/main.ts": "Worker entry"
  }
}
```

## Token Optimization

The index file is:
- Compact JSON (~50-100 lines)
- Loaded only when /search is used
- Updated on demand, not every session
- Contains pointers, not content

## Example Output

```
Project index generated: .claude/project-index.json

Summary:
- Type: TypeScript/React
- Entry: src/index.tsx
- 15 key directories mapped
- 8 entry points identified

Use /search to find files quickly.
```
