# /search - Efficient Codebase Search

Search the codebase efficiently with minimal token usage.

## Usage
- `/search <query>` - Smart search for files, functions, classes
- `/search --files <pattern>` - Find files by name
- `/search --def <name>` - Find function/class definitions
- `/search --content <pattern>` - Find content in files

## Instructions

Use the search skill for implementation details.

### Quick Reference

1. **File search**: Convert query to glob patterns, limit to 10 results
2. **Definition search**: Use language-specific regex patterns
3. **Content search**: Use Grep with context, limit to 20 matches

### Output Format
Return compact results with file:line and 1-line preview.

### Token Optimization
- Never read full files during search
- Stop when likely match found
- Use head_limit in all Grep calls
- Skip node_modules, dist, .git, vendor

## Examples

```
/search user authentication
→ Files matching *user*auth* pattern

/search --def handleSubmit
→ Function/const definitions named handleSubmit

/search --files service
→ Files with "service" in the name

/search --content deprecated
→ Lines containing "deprecated"
```
