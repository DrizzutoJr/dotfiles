#!/bin/bash

# Guard against double-sourcing
if [[ -n "$_HELPERS_COMMON_LOADED" ]]; then
    return 0
fi
_HELPERS_COMMON_LOADED=1

# Resolve REPO_DIR from this helper's location (_helpers/ is a direct child of repo root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_DIR

# Parse arguments - NON_INTERACTIVE defaults to false unless already set by caller
if [[ -z "$NON_INTERACTIVE" ]]; then
    NON_INTERACTIVE=false
fi
for arg in "$@"; do
    case $arg in
        --non-interactive)
            NON_INTERACTIVE=true
            ;;
    esac
done

# Helper function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local target_dir
    target_dir="$(dirname "$target")"

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
