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

backup_target() {
    local target="$1"
    local backup_dir
    backup_dir="$(mktemp -d "${target}.bak.XXXXXX")" || return 1

    if ! mv "$target" "$backup_dir/original"; then
        rmdir "$backup_dir" 2>/dev/null || true
        return 1
    fi

    printf '%s\n' "$backup_dir/original"
}

link_with_backup() {
    local source="$1"
    local target="$2"
    local target_dir backup_path
    target_dir="$(dirname "$target")"

    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        echo "..Already linked: $target"
        return 0
    fi

    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        echo "..Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        backup_path="$(backup_target "$target")" || return 1
        echo "..Backed up $target to $backup_path"
    fi

    echo "..Linking $source -> $target"
    if ! ln -s "$source" "$target"; then
        if [[ -n "$backup_path" && ! -e "$target" && ! -L "$target" ]]; then
            if mv "$backup_path" "$target"; then
                rmdir "$(dirname "$backup_path")" 2>/dev/null || true
            else
                echo "! Could not restore $target; original is at $backup_path" >&2
            fi
        fi
        return 1
    fi
}

# Helper function to create file symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"

    if [[ ! -f "$source" ]]; then
        echo "! Missing source file: $source" >&2
        return 1
    fi

    link_with_backup "$source" "$target"
}

# Helper function to create directory symlink with backup
create_dir_symlink() {
    local source="$1"
    local target="$2"

    if [[ ! -d "$source" ]]; then
        echo "! Missing source directory: $source" >&2
        return 1
    fi

    link_with_backup "$source" "$target"
}
