# Skill: search

Efficient codebase search with fuzzy matching and minimal token usage.

## Trigger
- `/search <query>` - Search for files, functions, classes
- `/search --files <pattern>` - Find files by fuzzy name match
- `/search --content <pattern>` - Find content in files
- `/search --def <name>` - Find function/class definitions

## Description
Smart search that minimizes token usage by:
1. Using targeted patterns instead of broad searches
2. Showing only relevant context (not full files)
3. Prioritizing likely matches
4. Stopping early when results are found
