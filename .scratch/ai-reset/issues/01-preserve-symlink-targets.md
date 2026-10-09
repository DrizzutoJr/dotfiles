# 01: Preserve symlink targets safely

**What to build:** Rerunning dotfiles setup on an existing Mac preserves every displaced target in a unique local backup and leaves an already-correct managed link alone.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] An already-correct symlink is a no-op and produces no backup.
- [x] A conflicting regular file, directory, or unrelated symlink receives a unique backup before the managed link replaces it.
- [x] Existing backups are never overwritten, including on repeated setup runs.
- [x] A failed backup or link operation reports an error without discarding the original target.
- [x] Temporary-home tests exercise file, directory, and symlink conflicts; changed shell code passes syntax and ShellCheck checks.
