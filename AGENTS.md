# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## Setup Command

Run the full macOS setup (creates symlinks, installs brew packages, installs VS Code extensions):
```bash
./macos_setup.sh
```

Run individual tool setup independently:
```bash
bash <tool>/macos_setup.sh [--non-interactive]
```

Prerequisites: Homebrew and yq must be installed.

## Architecture

This is a dotfiles repository that manages configuration files via symlinks from the repo to their expected locations in the home directory.

### Symlink Mapping

| Repo Path | Target Location |
|-----------|-----------------|
| `bash/bash_profile` | `~/.bash_profile` |
| `zsh/zshrc` | `~/.zshrc` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `claude_code/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude_code/skills/` | `~/.claude/skills` |
| `claude_code/commands/` | `~/.claude/commands` |
| `sublime/settings.json` | `~/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings` |
| `sublime/CandyLand.tmTheme` | `~/Library/Application Support/Sublime Text/Packages/User/CandyLand.tmTheme` |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| `vscode/keybindings.json` | `~/Library/Application Support/Code/User/keybindings.json` |

### Key Files

- `macos_setup.sh` - Root orchestrator that calls all sub-directory setup scripts
- `_helpers/common.sh` - Shared functions (`create_symlink`, `create_dir_symlink`) and argument parsing
- `<tool>/macos_setup.sh` - Per-directory setup scripts (independently runnable)
- `hosts/macos_setup.sh` - Prompts for per-machine values and writes `~/.dotfiles-config`
- `homebrew/brew_packages.yaml` - Homebrew packages to install (parsed with yq)
- `vscode/extensions/extension_list.yaml` - VS Code extensions to install from marketplace
- `vscode/extensions/*/` - Local `.vsix` extension files
- `claude_code/CLAUDE.md` - Global Claude Code behavioral settings (symlinked to ~/.claude/CLAUDE.md)
- `claude_code/skills/` - Custom Claude Code skills (symlinked to ~/.claude/skills)
- `claude_code/commands/` - Custom Claude Code commands (symlinked to ~/.claude/commands)

### Adding New Dotfiles

1. Add the config file to the appropriate directory (or create a new one)
2. Create a `macos_setup.sh` in the directory that sources `_helpers/common.sh` and uses `create_symlink` or `create_dir_symlink`
3. Add the new sub-script call to the root `macos_setup.sh` orchestrator

### Per-Machine Values

Values that differ between machines (developer root, brew prefix, username, openbao CA
cert path) are never derived or looked up in a committed table — a machine only ever needs
its own values, and directory names differ enough between machines that no derivation
scheme would get them right.

`hosts/macos_setup.sh` runs first in the orchestrator. On first run it prompts for each
value and writes them to `~/.dotfiles-config`, outside the repo and never committed. On
later runs it shows the current values and asks whether to keep them or change them.
`dotfiles_root` is never typed — it is always the clone the script is running from.
`zsh/zshrc` sources `~/.dotfiles-config` (a `DOTFILES_CONFIG` associative array) before its
Homebrew block, which consumes `brew_prefix`. Read values with the `host_config <key>`
helper, which fails loudly on a missing array or missing key rather than returning empty.

Since `/bin/bash` on macOS has no associative arrays, `hosts/macos_setup.sh` reads an
existing config by delegating to `zsh -c` to dump `DOTFILES_CONFIG` as tab-separated pairs.

## Important Note

The `claude_code/CLAUDE.md` file in this repo is **not** repo-specific guidance. It contains global Claude Code behavioral settings that get symlinked to `~/.claude/CLAUDE.md`. Do not modify it for repo-specific instructions - use this root `AGENTS.md` instead.


## Behaviours

- Lint code after making changes to ensure changes pass
