#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Helper function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local target_dir="$(dirname "$target")"

    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        echo "..Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi

    # Backup existing file if it's not already a symlink
    if [[ -f "$target" && ! -L "$target" ]]; then
        echo "..Backing up existing file: $target"
        mv "$target" "${target}.bak"
    fi

    # Remove existing symlink if present
    if [[ -L "$target" ]]; then
        rm "$target"
    fi

    echo "..Linking $source -> $target"
    ln -sf "$source" "$target"
}

# Helper function to create directory symlink with backup
create_dir_symlink() {
    local source="$1"
    local target="$2"

    # Backup existing directory if it's not already a symlink
    if [[ -d "$target" && ! -L "$target" ]]; then
        echo "..Backing up existing directory: $target"
        mv "$target" "${target}.bak"
    fi

    # Remove existing symlink if present
    if [[ -L "$target" ]]; then
        rm "$target"
    fi

    echo "..Linking $source -> $target"
    ln -sf "$source" "$target"
}

echo "=== macOS Dotfiles Setup ==="

# Check if VS Code is running
if pgrep -x "Code" > /dev/null; then
    echo "! Error: Visual Studio Code is running. Please quit VS Code and try again." >&2
    exit 1
fi

if [ "$(osascript -e 'application "Visual Studio Code" is running')" = "true" ]; then
    echo "! Error: Visual Studio Code is running. Please quit VS Code and try again." >&2
    exit 1
fi

# Check if tmux is running
SKIP_TMUX=false
if pgrep tmux > /dev/null; then
    echo ""
    echo "! Warning: tmux is currently running."
    read -p "Kill tmux server and continue? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "..Killing tmux server"
        tmux kill-server
    else
        echo "..Skipping tmux config setup"
        SKIP_TMUX=true
    fi
fi

# Change shell to zsh
echo ""
echo "Changing shell to zsh"
chsh -s /bin/zsh

# Bash
echo ""
echo "Setting up bash profile"
create_symlink "$REPO_DIR/bash/bash_profile" "$HOME/.bash_profile"

# Zsh
echo ""
echo "Setting up zsh config"
create_symlink "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"

# Tmux
if [[ "$SKIP_TMUX" == false ]]; then
    echo ""
    echo "Setting up tmux config"
    create_symlink "$REPO_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
fi

# Claude Code
echo ""
echo "Setting up Claude Code config"
CLAUDE_DIR="$HOME/.claude"

# If ~/.claude is a symlink (from old setup), remove it
if [[ -L "$CLAUDE_DIR" ]]; then
    echo "..Removing old symlink: $CLAUDE_DIR"
    rm "$CLAUDE_DIR"
fi

# Create ~/.claude directory if it doesn't exist
if [[ ! -d "$CLAUDE_DIR" ]]; then
    echo "..Creating directory: $CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR"
fi

create_symlink "$REPO_DIR/claude_code/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
create_dir_symlink "$REPO_DIR/claude_code/skills" "$CLAUDE_DIR/skills"
create_dir_symlink "$REPO_DIR/claude_code/commands" "$CLAUDE_DIR/commands"

# Sublime Text
echo ""
echo "Setting up Sublime Text config"
SUBLIME_USER_DIR="$HOME/Library/Application Support/Sublime Text/Packages/User"
create_symlink "$REPO_DIR/sublime/settings.json" "$SUBLIME_USER_DIR/Preferences.sublime-settings"
create_symlink "$REPO_DIR/sublime/CandyLand.tmTheme" "$SUBLIME_USER_DIR/CandyLand.tmTheme"

# VS Code
echo ""
echo "Setting up VS Code"
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

# Homebrew packages
echo ""
echo "Setting up Homebrew"
BREW_PACKAGES_FILE_PATH="$SCRIPT_DIR/brew_packages.yaml"

if ! command -v brew &> /dev/null; then
    echo "! Error: brew not installed. Please install it first." >&2
    exit 1
fi

if [[ -f "$BREW_PACKAGES_FILE_PATH" ]]; then
    echo "Installing homebrew packages"
    for package in $(yq '.packages[]' "$BREW_PACKAGES_FILE_PATH"); do
        echo "..Installing brew package: $package"
        brew install "$package"
    done
else
    echo "..No brew_packages.yaml found, skipping"
fi

echo ""
echo "=== Setup complete ==="
