# Smart Search

Efficient codebase search that minimizes token usage.

## First: Check Project Index

If `.claude/project-index.json` exists, read it first:
1. Check if `stale: true` - if so, suggest running `/index --update`
2. Use `entryPoints` to prioritize search locations
3. Use `structure` to skip irrelevant directories
4. Use `keyFiles` for definition lookups

If index doesn't exist, suggest running `/index` for faster future searches.
If index has `stale: true`, mention it but still use the index data.

## Strategy

### 1. File Search (--files or implicit)
Convert query to glob patterns. For "user auth":
```
**/user*auth*.{ts,js,py,go,rs}
**/auth*user*.{ts,js,py,go,rs}
**/*User*Auth*.{ts,js,py,go,rs}
```

Use Glob tool with LIMIT of 10 files. Stop when found.

### 2. Definition Search (--def)
Use Grep with targeted patterns:
- TypeScript/JS: `(function|const|class|interface)\s+{name}`
- Python: `(def|class)\s+{name}`
- Go: `func\s+(\([^)]+\)\s+)?{name}`
- Rust: `(fn|struct|enum|trait)\s+{name}`

Show only 3 lines of context (-C 3).

### 3. Content Search (--content)
Use Grep with:
- Case insensitive (-i) by default
- File type filter based on project
- LIMIT to 20 matches
- Show 2 lines context (-C 2)

### 4. Fuzzy Matching
Split query into parts. "usrauth" → "usr" + "auth"
Search for: `*usr*auth*` or `*auth*usr*`

## Output Format

Return compact results:
```
Found 3 matches:

1. src/auth/userAuth.ts:45
   → class UserAuthService

2. src/models/user.ts:12
   → interface AuthUser

3. tests/auth.test.ts:89
   → describe("user auth")
```

## Token Optimization

1. NEVER read full files during search
2. Stop after finding likely match (don't exhaustively search)
3. Use head_limit parameter in Grep
4. Prefer files_with_matches mode first, then content mode
5. For definition search, read only the matching function/class

## Search Order

1. Check common directories first:
   - src/, lib/, app/, pkg/
   - components/, services/, utils/
   - tests/, __tests__/

2. Skip irrelevant directories:
   - node_modules/, vendor/, .git/
   - dist/, build/, coverage/
   - __pycache__/, .next/

## Examples

`/search user authentication`
→ Glob: `**/*user*auth*.{ts,js,tsx,jsx}`
→ If empty, Grep: `user.*auth|auth.*user`

`/search --def handleLogin`
→ Grep: `(function|const|async function)\s+handleLogin`

`/search --files config`
→ Glob: `**/*config*.{ts,js,json,yaml,yml,toml}`

`/search --content TODO`
→ Grep: `TODO|FIXME|HACK` with files_with_matches first
