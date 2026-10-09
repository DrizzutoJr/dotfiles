# 03: Install declared plugins

**What to build:** Agent setup installs the declared Matt Pocock plugin into the Codex user's environment from a reproducible source, while leaving plugin payloads and credentials outside dotfiles.

**Blocked by:** 02: Establish shared global instructions.

**Status:** resolved

- [x] A YAML declaration records the plugin, its marketplace source, and a fetchable pinned ref based on the current installation.
- [x] Interactive setup offers pinned or latest; unattended setup selects pinned without prompting.
- [x] Choosing latest for one run does not rewrite the pin.
- [x] A successful rerun recognizes an already installed plugin and avoids destructive reinstall behavior.
- [x] Missing commands or marketplace failures return a clear nonzero result without deleting existing plugin data or instruction links.
- [x] Isolated tests verify command selection, success, reruns, and failure; user-facing setup guidance and shell lint pass.
