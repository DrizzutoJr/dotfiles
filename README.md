# dotfiles

Personal macOS dotfiles. Config files live in this repo and are symlinked out to where
each tool expects them (`~/.zshrc`, `~/.tmux.conf`, VS Code and Sublime settings, AI agent
instructions, etc).

## Prerequisites

- [Homebrew](https://brew.sh)
- `yq` (installed automatically by the Homebrew step below if missing)

## First-time setup on a new machine

```bash
git clone git@github.com:DrizzutoJr/dotfiles.git
cd dotfiles
./macos_setup.sh
```

Run it from a plain terminal, **not** inside tmux — the tmux step prompts if tmux is
already running, and answering anything but `y` aborts the whole run; `y` skips relinking
`~/.tmux.conf` for that pass.

The first thing `macos_setup.sh` does is run `hosts/macos_setup.sh`, which asks for a
handful of values that differ on every machine (your Developer folder, Homebrew prefix,
username, an openbao cert path). Confirm the directory you cloned into as your dotfiles
root, answer the rest, and it writes `~/.dotfiles-config`. Nothing you type here is
committed to the repo — it stays local to the machine. After that, setup runs through
each tool in turn: zsh, bash, Homebrew packages, AI agents, tmux, Sublime, VS Code,
openbao. The AI step links one shared global instruction file for Claude Code and Codex.

`chsh -s /bin/zsh` runs as part of the zsh step and may prompt for your password.

## Re-running setup

Safe to re-run any time, on any machine, including ones that ran an older version of this
repo. Every symlink is recreated pointing at whichever clone you ran the script from:

```bash
./macos_setup.sh
```

or just one tool:

```bash
bash <tool>/macos_setup.sh [--non-interactive]
```

`hosts/macos_setup.sh` will show your existing `~/.dotfiles-config` values and ask whether
to keep them or change them. `--non-interactive` skips all prompts and uses whatever is
already saved — it errors out if no config exists yet, since there's nothing to prompt
for. That means the very first run on a machine has to be interactive.

If a target already exists and differs from the managed symlink, setup saves it under a
unique `<target>.bak.XXXXXX/original` directory before replacing it. A correct symlink is
left alone.

## Layout

| Path | What it is |
|---|---|
| `macos_setup.sh` | Root orchestrator — runs every `<tool>/macos_setup.sh` in order |
| `_helpers/common.sh` | Shared `create_symlink` / `create_dir_symlink` helpers, `--non-interactive` parsing |
| `hosts/macos_setup.sh` | Prompts for per-machine values, writes `~/.dotfiles-config` |
| `<tool>/macos_setup.sh` | Per-tool setup, independently runnable |
| `zsh/zshrc`, `bash/bash_profile` | Shell config |
| `tmux/tmux.conf` | tmux config |
| `ai/` | Active global instructions and setup for Claude Code and Codex |
| `Legacy_AI/` | Archived tracked Claude Code configuration for later review |
| `homebrew/brew_packages.yaml` | Packages and casks installed by the Homebrew step |
| `vscode/`, `sublime/` | Editor settings, keybindings, themes, extensions |
| `openbao/aliases-homelab.sh` | openbao login helpers |

See `AGENTS.md` for the full symlink mapping and more detail on how per-machine values
work.

## AI agent configuration

`ai/AGENTS.md` is the shared global guidance for Claude Code and Codex.
Run `bash ai/macos_setup.sh [--non-interactive]` to configure just the agents. Old tracked
Claude configuration is preserved in `Legacy_AI/` for selective porting later. The setup
backs up prior user instruction files locally and leaves credentials and sessions in each
app's own directory.

`ai/plugins.yaml` declares third-party plugin installs. It installs `mattpocock-skills`
for Codex and Cursor, the community-maintained [pstack port](https://github.com/michael-denyer/pstack-claude)
for Codex and Claude Code, and the official [pstack](https://github.com/cursor/plugins/tree/main/pstack)
for Cursor. Each declaration has a Git commit pin, and plugin files stay in the user's
agent directories. Interactive setup asks whether to use pinned refs or the latest
versions; `--non-interactive` uses the pins. Codex uses its marketplace ref, Claude Code
uses a per-user marketplace entry with a pinned Git source, and Cursor loads managed copies
from `~/.cursor/plugins/local/`. Cursor needs local plugin imports enabled and a window
reload to discover new plugins. Setup refuses to replace locally changed Cursor plugins and
backs up managed copies before updates. A pinned rerun leaves matching installed plugins
alone. The latest choice affects that machine only and does not update `ai/plugins.yaml`.

`ai/skills/drjr-skills/` is the local `drjr-skills` plugin for both agents. Its first
skill is `explain-code`; add future authored skills under its `skills/` directory so they
install together. Setup registers `ai/skills/` as a local marketplace in Claude Code and
Codex, then installs `drjr-skills@drjr` at user scope. When the collection changes, bump
the plugin version in its manifest and rerun setup to update both installations. The
former standalone `explain-code` skill and its local backups move to each agent's
`skill-backups/` directory so the plugin supplies the only active copy.

## Adding a new dotfile

1. Add the config file to the appropriate directory (or create a new one).
2. Add a `macos_setup.sh` in that directory that sources `_helpers/common.sh` and calls
   `create_symlink` or `create_dir_symlink`.
3. Add a call to it from the root `macos_setup.sh`.
