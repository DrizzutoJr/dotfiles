#!/bin/bash

set -e

manifest="$1"
selection="$2"
if ! command -v git >/dev/null 2>&1; then
    echo "! Git is required to install Claude Code plugins" >&2
    exit 1
fi
if [[ "$selection" != pinned && "$selection" != latest ]]; then
    echo "! Plugin selection must be pinned or latest" >&2
    exit 1
fi
plugin_count="$(yq -r '.plugins | length' "$manifest")"
marketplace_parent="$HOME/.claude/plugins/dotfiles-marketplaces"

for ((plugin_index=0; plugin_index<plugin_count; plugin_index++)); do
    agent="$(yq -r ".plugins[$plugin_index].agent" "$manifest")"
    [[ "$agent" == claude ]] || continue

    name="$(yq -r ".plugins[$plugin_index].name" "$manifest")"
    marketplace="$(yq -r ".plugins[$plugin_index].marketplace" "$manifest")"
    source="$(yq -r ".plugins[$plugin_index].source" "$manifest")"
    ref="$(yq -r ".plugins[$plugin_index].ref" "$manifest")"
    if [[ -z "$name" || "$name" == null || -z "$marketplace" || "$marketplace" == null || -z "$source" || "$source" == null || ! "$ref" =~ ^[a-f0-9]{40}$ ]]; then
        echo "! Invalid Claude Code plugin declaration at index $plugin_index" >&2
        exit 1
    fi

    target="$marketplace_parent/$marketplace"
    selector="$name@$marketplace"
    marker="$target/.dotfiles-source"
    mkdir -p "$marketplace_parent"
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ ! -d "$target/.git" || ! -f "$marker" || "$(cat "$marker")" != "$source" ]]; then
            echo "! Existing Claude Code marketplace checkout is not managed by dotfiles: $target" >&2
            exit 1
        fi
        if [[ -n "$(git -C "$target" status --porcelain --untracked-files=no)" ]]; then
            echo "! Claude Code marketplace checkout has local changes: $target" >&2
            exit 1
        fi
    fi

    marketplaces="$(claude plugin marketplace list --json)" || {
        echo "! Could not list Claude Code marketplaces" >&2
        exit 1
    }
    existing_path="$(printf '%s\n' "$marketplaces" | PLUGIN_MARKETPLACE="$marketplace" yq -r '.[] | select(.name == strenv(PLUGIN_MARKETPLACE)) | .path // .repo // ""')" || exit 1
    if [[ -n "$existing_path" && "$existing_path" != "$target" ]]; then
        echo "! Claude Code marketplace $marketplace uses a different source: $existing_path" >&2
        exit 1
    fi
    if [[ -n "$existing_path" && ! -d "$target" ]]; then
        echo "! Claude Code marketplace $marketplace has missing local state: $target" >&2
        exit 1
    fi

    installed="$(claude plugin list --json)" || {
        echo "! Could not list installed Claude Code plugins" >&2
        exit 1
    }
    installed_id="$(printf '%s\n' "$installed" | PLUGIN_SELECTOR="$selector" yq -r '.[] | select(.id == strenv(PLUGIN_SELECTOR) and .scope == "user") | .id')" || exit 1

    changed=false
    backup_dir=
    current_ref=
    if [[ -d "$target/.git" ]]; then
        current_ref="$(git -C "$target" rev-parse HEAD)"
    fi
    if [[ "$selection" == latest || "$current_ref" != "$ref" ]]; then
        staging="$(mktemp -d "$marketplace_parent/$marketplace.stage.XXXXXX")"
        if ! git clone --quiet "$source" "$staging"; then
            rm -rf "$staging"
            echo "! Could not fetch Claude Code marketplace $marketplace" >&2
            exit 1
        fi
        if [[ "$selection" == pinned ]] && ! git -C "$staging" checkout --detach --quiet "$ref"; then
            rm -rf "$staging"
            echo "! Could not check out pinned Claude Code marketplace $marketplace ($ref)" >&2
            exit 1
        fi
        printf '%s\n' "$source" > "$staging/.dotfiles-source"
        new_ref="$(git -C "$staging" rev-parse HEAD)"
        if [[ "$new_ref" != "$current_ref" ]]; then
            if [[ -d "$target" ]]; then
                backup_dir="$(mktemp -d "$marketplace_parent/$marketplace.backup.XXXXXX")"
                mv "$target" "$backup_dir/previous"
            fi
            mv "$staging" "$target"
            changed=true
        else
            # The local checkout already has the selected revision.
            rm -rf "$staging"
        fi
    fi

    if [[ -z "$existing_path" ]]; then
        if ! claude plugin marketplace add "$target"; then
            if [[ -n "$backup_dir" ]]; then
                mv "$target" "$backup_dir/failed"
                mv "$backup_dir/previous" "$target"
            fi
            echo "! Could not add Claude Code marketplace $marketplace" >&2
            exit 1
        fi
    fi

    if [[ -z "$installed_id" ]]; then
        if ! claude plugin install "$selector" --scope user --json >/dev/null; then
            if [[ -n "$backup_dir" ]]; then
                mv "$target" "$backup_dir/failed"
                mv "$backup_dir/previous" "$target"
            fi
            echo "! Could not install Claude Code plugin $selector" >&2
            exit 1
        fi
        echo "..Installed Claude Code plugin: $selector ($selection)"
    elif [[ "$changed" == true || "$selection" == latest ]]; then
        if ! claude plugin update "$selector" --scope user --json >/dev/null; then
            if [[ -n "$backup_dir" ]]; then
                mv "$target" "$backup_dir/failed"
                mv "$backup_dir/previous" "$target"
                echo "! Restored prior Claude Code marketplace checkout; failed copy: $backup_dir/failed" >&2
            fi
            echo "! Could not update Claude Code plugin $selector" >&2
            exit 1
        fi
        echo "..Updated Claude Code plugin: $selector ($selection)"
    else
        echo "..Claude Code plugin already installed: $selector"
    fi
done
