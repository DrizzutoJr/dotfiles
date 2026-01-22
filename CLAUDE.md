# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup Command

Run the full macOS setup (creates symlinks, installs brew packages, installs VS Code extensions):
```bash
./macos_setup.sh
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

- `macos_setup.sh` - Main setup script with `create_symlink()` and `create_dir_symlink()` helper functions
- `homebrew/brew_packages.yaml` - Homebrew packages to install (parsed with yq)
- `vscode/extensions/extension_list.yaml` - VS Code extensions to install from marketplace
- `vscode/extensions/*/` - Local `.vsix` extension files
- `claude_code/CLAUDE.md` - Global Claude Code behavioral settings (symlinked to ~/.claude/CLAUDE.md)
- `claude_code/skills/` - Custom Claude Code skills (symlinked to ~/.claude/skills)
- `claude_code/commands/` - Custom Claude Code commands (symlinked to ~/.claude/commands)

### Adding New Dotfiles

1. Add the config file to the appropriate directory (or create a new one)
2. Update `macos_setup.sh` to create the symlink using `create_symlink` or `create_dir_symlink`

## Important Note

The `claude_code/CLAUDE.md` file in this repo is **not** repo-specific guidance. It contains global Claude Code behavioral settings that get symlinked to `~/.claude/CLAUDE.md`. Do not modify it for repo-specific instructions - use this root `CLAUDE.md` instead.
