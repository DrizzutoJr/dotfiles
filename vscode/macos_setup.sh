#!/bin/bash

# shellcheck source=../_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"

echo ""
echo "Setting up VS Code"

# Check if VS Code is running
if [ "$(osascript -e 'application "Visual Studio Code" is running')" = "true" ]; then
    echo "! Warning: Visual Studio Code is currently running."
    if [[ "$NON_INTERACTIVE" == true ]]; then
        echo "..Skipping VS Code setup (non-interactive mode)"
        exit 0
    else
        read -p "Skip VS Code setup? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "..Skipping VS Code setup"
            exit 0
        else
            echo "! Please quit VS Code and run the script again." >&2
            exit 1
        fi
    fi
fi

VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_EXTENSIONS_DIR="$REPO_DIR/vscode/extensions"
VSCODE_EXTENSION_LIST="$VSCODE_EXTENSIONS_DIR/extension_list.yaml"

if ! command -v code &> /dev/null; then
    echo "! Warning: VS Code CLI not found. Skipping extension installation."
    echo "..Run 'Shell Command: Install code command in PATH' from VS Code to enable."
else
    # Install local extensions (.vsix files)
    echo "Installing local VS Code extensions"
    for vsix_file in "$VSCODE_EXTENSIONS_DIR"/*/*.vsix; do
        if [[ -f "$vsix_file" ]]; then
            echo "..Installing extension: $(basename "$vsix_file")"
            code --install-extension "$vsix_file"
        fi
    done

    # Install extensions from extension_list.yaml
    if [[ -f "$VSCODE_EXTENSION_LIST" ]]; then
        echo "Installing VS Code extensions from list"
        for extension in $(yq '.extensions[]' "$VSCODE_EXTENSION_LIST"); do
            echo "..Installing extension: $extension"
            code --install-extension "$extension"
        done
    fi
fi

echo "Setting up VS Code config symlinks"
create_symlink "$REPO_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
create_symlink "$REPO_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
