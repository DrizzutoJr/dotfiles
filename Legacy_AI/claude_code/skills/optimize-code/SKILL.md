---
name: optimize-code
description: Analyze code changes for performance issues and suggest optimizations
---

When suggesting performance or optimization changes:

1. **Identify changed files**: Use `git diff --name-only` or `git status` to find modified files
2. **Review adjacent files**: Analyze imports, dependencies, and files referenced by changed code
3. **Look for optimization opportunities**:
   - Unnecessary re-renders or computations
   - N+1 queries or inefficient data fetching
   - Memory leaks or excessive allocations
   - Algorithmic complexity issues
   - Missing memoization/caching opportunities
4. **Run existing tests**: Execute `npm test` / `pytest` / relevant test command to establish baseline
5. **Propose changes**: For each suggestion, explain:
   - What the current issue is
   - The proposed fix
   - Expected performance benefit
   - Any risks or trade-offs
6. **Request approval**: Ask user before implementing any changes
