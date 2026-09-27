#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments and build arg array to forward
ARGS=()
for arg in "$@"; do
    case $arg in
        --non-interactive)
            ARGS+=(--non-interactive)
            ;;
    esac
done

echo "=== macOS Dotfiles Setup ==="

# Run each sub-script in order
bash "$SCRIPT_DIR/hosts/macos_setup.sh" "${ARGS[@]}" || exit 1
bash "$SCRIPT_DIR/zsh/macos_setup.sh" "${ARGS[@]}" || exit 1
bash "$SCRIPT_DIR/bash/macos_setup.sh" "${ARGS[@]}" || exit 1
bash "$SCRIPT_DIR/homebrew/macos_setup.sh" "${ARGS[@]}" || exit 1
bash "$SCRIPT_DIR/tmux/macos_setup.sh" "${ARGS[@]}" || exit 1
bash "$SCRIPT_DIR/claude_code/macos_setup.sh" "${ARGS[@]}" || exit 1
bash "$SCRIPT_DIR/sublime/macos_setup.sh" "${ARGS[@]}" || exit 1
bash "$SCRIPT_DIR/vscode/macos_setup.sh" "${ARGS[@]}" || exit 1
bash "$SCRIPT_DIR/openbao/macos_setup.sh" "${ARGS[@]}" || exit 1

echo ""
echo "=== Setup complete ==="
