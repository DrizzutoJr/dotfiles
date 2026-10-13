# 02: Establish shared global instructions

**What to build:** Fresh and existing Macs receive one newly written, brief global working contract in Claude Code and Codex, while tracked legacy Claude configuration remains available for selective porting later.

**Blocked by:** 01: Preserve symlink targets safely.

**Status:** resolved

- [x] One neutral source file supplies both agents' global instruction locations through managed symlinks.
- [x] The shared contract covers repository guidance, credential handling, and verification without porting old style or workflow prose.
- [x] Previously tracked Claude instructions, setup, and two custom skills are archived under the agreed legacy directory.
- [x] Existing managed legacy links are repointed or retired without deleting app-owned data; conflicting user files receive unique local backups.
- [x] Full setup invokes the agent step after app installation, and the agent step can run independently.
- [x] Fresh-home, migration, and rerun behavior are verified in isolation; documentation and shell lint match the new setup.
