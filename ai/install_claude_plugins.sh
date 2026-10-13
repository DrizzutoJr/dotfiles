#!/bin/bash

set -e

manifest="$1"
selection="$2"
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
    path="$(yq -r ".plugins[$plugin_index].path" "$manifest")"
    ref="$(yq -r ".plugins[$plugin_index].ref" "$manifest")"
    if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ || ! "$marketplace" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ || "$source" != https://* || "$path" != plugins/* || ! "$ref" =~ ^[a-f0-9]{40}$ ]]; then
        echo "! Invalid Claude Code plugin declaration at index $plugin_index" >&2
        exit 1
    fi

    target="$marketplace_parent/$marketplace"
    selector="$name@$marketplace"
    marker="$target/.dotfiles-source"
    mkdir -p "$marketplace_parent"
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ ! -d "$target" || ! -f "$marker" || "$(cat "$marker")" != "$source" ]]; then
            echo "! Existing Claude Code marketplace is not managed by dotfiles: $target" >&2
            exit 1
        fi
        if [[ -d "$target/.git" ]]; then
            # Migrate the earlier managed clone without losing local edits.
            if [[ -n "$(git -C "$target" status --porcelain --untracked-files=all -- . ':(exclude).dotfiles-source')" ]]; then
                echo "! Claude Code marketplace checkout has local changes: $target" >&2
                exit 1
            fi
        elif [[ ! -f "$target/.dotfiles-manifest-sha256" || "$(shasum -a 256 "$target/.claude-plugin/marketplace.json" | cut -d ' ' -f 1)" != "$(cat "$target/.dotfiles-manifest-sha256")" ]]; then
            echo "! Claude Code marketplace manifest has local changes: $target" >&2
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

    staging="$(mktemp -d "$marketplace_parent/$marketplace.stage.XXXXXX")"
    mkdir -p "$staging/.claude-plugin"
    if [[ "$selection" == pinned ]]; then
        PLUGIN_NAME="$name" PLUGIN_MARKETPLACE="$marketplace" PLUGIN_SOURCE="$source" PLUGIN_PATH="$path" PLUGIN_SHA="$ref" \
            yq -n -o=json '{"name": strenv(PLUGIN_MARKETPLACE), "owner": {"name": "dotfiles"}, "plugins": [{"name": strenv(PLUGIN_NAME), "source": {"source": "git-subdir", "url": strenv(PLUGIN_SOURCE), "path": strenv(PLUGIN_PATH), "sha": strenv(PLUGIN_SHA)}}]}' \
            > "$staging/.claude-plugin/marketplace.json"
    else
        PLUGIN_NAME="$name" PLUGIN_MARKETPLACE="$marketplace" PLUGIN_SOURCE="$source" PLUGIN_PATH="$path" \
            yq -n -o=json '{"name": strenv(PLUGIN_MARKETPLACE), "owner": {"name": "dotfiles"}, "plugins": [{"name": strenv(PLUGIN_NAME), "source": {"source": "git-subdir", "url": strenv(PLUGIN_SOURCE), "path": strenv(PLUGIN_PATH)}}]}' \
            > "$staging/.claude-plugin/marketplace.json"
    fi
    printf '%s\n' "$source" > "$staging/.dotfiles-source"
    shasum -a 256 "$staging/.claude-plugin/marketplace.json" | cut -d ' ' -f 1 > "$staging/.dotfiles-manifest-sha256"
    if ! claude plugin validate "$staging" >/dev/null; then
        rm -rf "$staging"
        echo "! Invalid Claude Code marketplace for $selector" >&2
        exit 1
    fi

    changed=false
    backup_dir=
    if [[ ! -d "$target" || ! -f "$target/.claude-plugin/marketplace.json" ]] || ! cmp -s "$target/.claude-plugin/marketplace.json" "$staging/.claude-plugin/marketplace.json"; then
        if [[ -d "$target" ]]; then
            backup_dir="$(mktemp -d "$marketplace_parent/$marketplace.backup.XXXXXX")"
            mv "$target" "$backup_dir/previous"
        fi
        mv "$staging" "$target"
        changed=true
    else
        rm -rf "$staging"
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
                echo "! Restored prior Claude Code marketplace; failed copy: $backup_dir/failed" >&2
            fi
            echo "! Could not update Claude Code plugin $selector" >&2
            exit 1
        fi
        echo "..Updated Claude Code plugin: $selector ($selection)"
    else
        echo "..Claude Code plugin already installed: $selector"
    fi
done
