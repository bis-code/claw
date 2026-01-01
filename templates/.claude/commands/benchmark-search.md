# /benchmark-search - Compare Search Efficiency

Benchmark search performance with and without project index.

## Usage
- `/benchmark-search` - Run full benchmark
- `/benchmark-search --quick` - Quick 3-query test

## Instructions

### Phase 1: Baseline (No Index)

1. Remove or rename existing index:
   ```bash
   mv .claude/project-index.json .claude/project-index.json.bak 2>/dev/null || true
   ```

2. Run 5 test searches, counting operations:
   - Search 1: Find main entry point (e.g., "main", "index", "app")
   - Search 2: Find a config file
   - Search 3: Find a specific function (pick from codebase)
   - Search 4: Find test files
   - Search 5: Find API/route handlers

3. For each search, record:
   - Number of Glob calls made
   - Number of Grep calls made
   - Number of Read calls made
   - Total files examined

### Phase 2: Generate Index

Run `/index` and record:
- Time to generate (approximate)
- Index file size
- Number of entries

### Phase 3: With Index

1. Run the SAME 5 searches again

2. For each search, record:
   - Number of Glob calls made
   - Number of Grep calls made
   - Number of Read calls made
   - Total files examined

### Phase 4: Report

Generate comparison table:

```
## Search Benchmark Results

| Search | Without Index | With Index | Improvement |
|--------|---------------|------------|-------------|
| Entry point | 4 ops, 12 files | 1 op, 2 files | 75% fewer |
| Config | 3 ops, 8 files | 1 op, 1 file | 87% fewer |
| Function | 5 ops, 15 files | 2 ops, 3 files | 80% fewer |
| Tests | 2 ops, 6 files | 1 op, 2 files | 66% fewer |
| API routes | 4 ops, 10 files | 1 op, 2 files | 80% fewer |

### Summary
- Average operations: 3.6 → 1.2 (67% reduction)
- Average files examined: 10.2 → 2.0 (80% reduction)
- Estimated token savings: ~60-80% per search

### Index Stats
- Generation time: ~5 seconds
- Index size: 2.1 KB
- Entries: 45 files mapped
```

## Output Format

Save results to `.claude/benchmark-results.md` for future reference.

## Notes

- Run on a medium-sized project (50-500 files) for meaningful results
- Results vary by project structure and query types
- The index pays off after 3-5 searches typically
