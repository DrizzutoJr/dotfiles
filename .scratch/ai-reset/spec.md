# AI agent setup reset

**Status:** ready-for-agent

## Problem Statement

The dotfiles setup currently manages global Claude Code instructions and custom skills but does not establish equivalent global guidance for Codex. Its Claude setup links whole skills and commands directories, including a commands source that does not exist. Existing agent instructions have accumulated behavior that the owner wants to review before reusing. The shared symlink helper uses a fixed backup name, making repeated setup unsafe when an older backup already exists. A fresh or existing Mac should get a consistent, deliberate agent setup without copying credentials, sessions, or installed plugin files into the repository.

## Solution

A single brief global instruction source serves both Claude Code and Codex through their respective user-level instruction locations. The setup installs the two apps through the existing Homebrew step, then configures global instructions and a declared third-party plugin at user scope. The owner can choose the pinned plugin release or the latest available release during interactive setup; unattended setup uses the pinned release. Previously tracked Claude configuration is kept in `Legacy_AI/` for selective porting later. Migration preserves existing user data in uniquely named local backups, and repeated setup converges on the desired links and plugin state.

## User Stories

1. As the owner setting up a fresh Mac, I want one command to install the agent apps and configure their global guidance, so I can start using both agents consistently.
2. As the owner setting up a fresh Mac, I want the declared third-party plugin installed into my Codex user environment, so the workflow is available without copying plugin files into dotfiles.
3. As the owner setting up a fresh Mac, I want no archived custom skills enabled by default, so the new setup starts from a minimal baseline.
4. As the owner using either agent in any repository, I want the same brief global working contract, so behavior does not drift between tools.
5. As the owner working in this dotfiles repository, I want repository guidance to remain distinct from global guidance, so setup details do not appear in every project.
6. As the owner changing global guidance, I want one source file to edit, so the two agents receive the same change after checkout on each Mac.
7. As the owner using multiple Macs, I want portable paths and declarations, so a clone can install from its own location without a machine lookup table.
8. As the owner migrating an existing Mac, I want current plain instruction files preserved before replacement, so I can recover prior content.
9. As the owner migrating an existing Mac, I want existing app credentials, sessions, plugin data, and preferences left in place, so setup does not reset my sign-ins or history.
10. As the owner migrating an existing Mac, I want legacy symlinks changed to the new managed source, so moving old tracked files does not leave broken global instructions.
11. As the owner migrating an existing Mac, I want obsolete managed directory links retired without deleting their targets, so a fresh layout does not hide or destroy legacy data.
12. As the owner rerunning setup, I want desired symlinks recognized and left intact, so routine runs do not create unnecessary backups.
13. As the owner rerunning setup with a conflicting target, I want a unique backup every time, so an earlier backup is never overwritten.
14. As the owner running full setup, I want the agent step after Homebrew, so the agent commands are available when plugins are installed.
15. As the owner running only the agent step, I want a clear error if an agent command is absent, so I know which prerequisite to install.
16. As the owner running setup interactively, I want to choose pinned or latest plugin installation, so I control when a Mac tries a newer release.
17. As the owner running setup unattended, I want the pinned plugin choice without a prompt, so automation is repeatable.
18. As the owner choosing latest for one run, I want the repository's pin left unchanged, so other devices remain reproducible until I deliberately update the declaration.
19. As the owner running setup offline or with a marketplace failure, I want a clear nonzero result while existing plugin state and instruction links remain usable, so I can retry safely.
20. As the owner reviewing old instructions and skills, I want tracked legacy content together in `Legacy_AI/`, so I can port only selected parts later.
21. As the owner adding a future authored skill, I want a documented place and installation pattern that does not take over an agent's entire user skills directory, so app-managed and third-party skills can coexist.
22. As the owner reviewing changes, I want the setup's symlinks, backups, and plugin command choices verified in an isolated temporary home, so tests cannot alter my live agent state.

## Implementation Decisions

- The active agent source area is named `ai/`; the tracked legacy archive is named `Legacy_AI/`.
- The shared global contract is newly written and brief. It covers repository guidance, credential handling, and verification. The old communication style and workflow prose stays in the archive for later review.
- Both agent-specific global instruction locations link to one Markdown source. The source uses a neutral filename so working inside the active agent directory does not cause the same file to load a second time as project guidance.
- Agent setup manages individual global instruction links. It does not replace whole application directories or user skills directories.
- The first release manages no model, effort, theme, MCP, hook, permission, notification, or project-trust settings.
- A YAML declaration names each third-party plugin, its agent, marketplace source, and pinned Git ref or version when supported. Initially it declares only the Matt Pocock plugin for Codex. Installed plugin payloads stay in the user's app environment.
- Interactive plugin setup offers pinned and latest. The pinned choice is the default for unattended setup. Choosing latest for one run does not rewrite the declaration.
- Existing managed legacy links are retired or repointed. Conflicting user files and unknown links receive unique local backups before replacement. Credentials and app-owned state are not archived into the repository.
- The shared symlink helper gains collision-free backup behavior for all setup scripts, because the full orchestrator uses it across tools.
- Plugin installation failure returns a nonzero result with a useful message and preserves previously installed plugin data. A rerun can complete setup after the cause is resolved.
- Homebrew remains responsible for the Claude Code and Codex applications; the root orchestrator invokes the new agent setup after Homebrew.

## Testing Decisions

- Test externally visible setup behavior through the agent setup entry point with a temporary home directory and fake agent commands. Avoid assertions about private helper calls.
- Cover fresh setup, existing file migration, legacy symlinks, repeated setup, unique backup names, pinned and latest choices, unattended behavior, missing commands, and plugin failure.
- Exercise the shared symlink helper with temporary files and directories to verify that an existing backup is never overwritten.
- Check the root setup's ordering and README guidance against the implemented behavior.
- Run shell syntax checks and ShellCheck on changed shell scripts, and check Markdown changes for whitespace errors.

## Out of Scope

- Porting the archived Claude instructions or the two archived custom skills into the new baseline.
- Managing Claude Code plugins before one is explicitly declared.
- Synchronizing app credentials, login sessions, plugin caches, model choices, themes, MCP servers, hooks, or permissions.
- Supporting operating systems other than macOS.
- Running setup on the owner's live home directory as part of repository verification.

## Further Notes

- The current installed Matt Pocock marketplace provides a concrete Git commit for the initial pin. The declaration should record a source and ref that a new Mac can fetch, not a path into this Mac's cache.
- Claude Code currently supports project `AGENTS.md` on recent versions, but its user-level global guidance and Codex's user-level global guidance use different locations. The shared source therefore needs two links.
