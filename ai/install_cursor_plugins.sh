#!/bin/bash

set -euo pipefail

manifest="$1"
selection="$2"
if [[ "$selection" != pinned && "$selection" != latest ]]; then
    echo "! Plugin selection must be pinned or latest" >&2
    exit 1
fi

plugin_count="$(yq -r '.plugins | length' "$manifest")"
plugin_parent="$HOME/.cursor/plugins/local"
backup_parent="$HOME/.cursor/plugins/dotfiles-backups"
staging=

cleanup() {
    if [[ -n "$staging" && -d "$staging" ]]; then
        rm -rf "$staging"
    fi
}
trap cleanup EXIT

content_hash() (
    cd "$1"
    find . -type f ! -name .dotfiles-install -print | LC_ALL=C sort | while IFS= read -r file; do
        shasum -a 256 "$file"
    done | shasum -a 256 | cut -d ' ' -f 1
)

publish_cursor_skills() {
    local plugin_dir="$1"
    local skills_root="$plugin_dir/skills"
    [[ -d "$skills_root" ]] || return 0
    local dest_root="$HOME/.cursor/skills"
    mkdir -p "$dest_root"
    local skill_dir name dest marker
    for skill_dir in "$skills_root"/*/; do
        [[ -f "${skill_dir}SKILL.md" ]] || continue
        name="$(basename "$skill_dir")"
        dest="$dest_root/$name"
        marker="$dest/.dotfiles-plugin-skill"
        if [[ -e "$dest" || -L "$dest" ]]; then
            if [[ ! -f "$marker" ]]; then
                echo "! Cursor skill is not managed by dotfiles: $dest" >&2
                exit 1
            fi
            rm -rf "$dest"
        fi
        mkdir -p "$dest"
        cp -R "${skill_dir}." "$dest/"
        printf '%s\n' "$plugin_dir" > "$marker"
    done
}

for ((plugin_index=0; plugin_index<plugin_count; plugin_index++)); do
    agent="$(yq -r ".plugins[$plugin_index].agent" "$manifest")"
    [[ "$agent" == cursor ]] || continue

    name="$(yq -r ".plugins[$plugin_index].name" "$manifest")"
    source="$(yq -r ".plugins[$plugin_index].source" "$manifest")"
    path="$(yq -r ".plugins[$plugin_index].path" "$manifest")"
    ref="$(yq -r ".plugins[$plugin_index].ref" "$manifest")"
    if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ || "$source" != https://* || ( "$path" != . && ( ! "$path" =~ ^[a-zA-Z0-9][a-zA-Z0-9._/-]*$ || "$path" == *..* ) ) || ! "$ref" =~ ^[a-f0-9]{40}$ ]]; then
        echo "! Invalid Cursor plugin declaration at index $plugin_index" >&2
        exit 1
    fi

    target="$plugin_parent/$name"
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ ! -d "$target" || -L "$target" || ! -f "$target/.dotfiles-install" ]]; then
            echo "! Existing Cursor plugin is not managed by dotfiles: $target" >&2
            exit 1
        fi
        IFS=$'\t' read -r installed_source installed_ref installed_hash < "$target/.dotfiles-install"
        if [[ "$installed_source" != "$source" || "$installed_hash" != "$(content_hash "$target")" ]]; then
            echo "! Cursor plugin has local changes or a different source: $target" >&2
            exit 1
        fi
        if [[ "$selection" == pinned && "$installed_ref" == "$ref" ]]; then
            echo "..Cursor plugin already installed: $name"
            publish_cursor_skills "$target"
            continue
        fi
    fi

    mkdir -p "$plugin_parent"
    staging="$(mktemp -d "$plugin_parent/$name.stage.XXXXXX")"
    checkout="$staging/checkout"
    unpacked="$staging/unpacked"
    plugin="$staging/plugin"
    mkdir -p "$checkout" "$unpacked" "$plugin"
    git -C "$checkout" init -q
    git -C "$checkout" remote add origin "$source"
    desired_ref="$ref"
    [[ "$selection" == latest ]] && desired_ref=HEAD
    if ! git -C "$checkout" fetch -q --depth 1 origin "$desired_ref"; then
        echo "! Could not fetch Cursor plugin $name" >&2
        exit 1
    fi
    commit="$(git -C "$checkout" rev-parse FETCH_HEAD)"
    if [[ "$selection" == pinned && "$commit" != "$ref" ]]; then
        echo "! Cursor plugin $name did not resolve to its pinned ref" >&2
        exit 1
    fi
    if [[ "$path" == . ]]; then
        git -C "$checkout" archive --format=tar "$commit" | tar -xf - -C "$unpacked"
    else
        git -C "$checkout" archive --format=tar "$commit" "$path" | tar -xf - -C "$unpacked"
    fi
    if [[ ! -d "$unpacked/$path" ]]; then
        echo "! Cursor plugin path is missing: $path" >&2
        exit 1
    fi
    cp -R "$unpacked/$path/." "$plugin/"

    if [[ "$name" == mattpocock-skills && -f "$plugin/.claude-plugin/plugin.json" ]]; then
        mkdir -p "$plugin/.cursor-plugin"
        yq -p=json -o=json '{"name": .name, "version": .version, "description": .description, "skills": .skills}' \
            "$plugin/.claude-plugin/plugin.json" > "$plugin/.cursor-plugin/plugin.json"
    fi
    if [[ ! -f "$plugin/plugin.json" && ! -f "$plugin/.cursor-plugin/plugin.json" ]]; then
        echo "! Cursor plugin $name has no supported plugin manifest" >&2
        exit 1
    fi

    hash="$(content_hash "$plugin")"
    printf '%s\t%s\t%s\n' "$source" "$commit" "$hash" > "$plugin/.dotfiles-install"
    if [[ -d "$target" ]]; then
        mkdir -p "$backup_parent"
        backup="$(mktemp -d "$backup_parent/$name.XXXXXX")"
        mv "$target" "$backup/previous"
        echo "..Backed up Cursor plugin to $backup/previous"
    fi
    if ! mv "$plugin" "$target"; then
        if [[ -n "${backup:-}" ]]; then
            mv "$backup/previous" "$target"
        fi
        echo "! Could not install Cursor plugin $name" >&2
        exit 1
    fi
    rm -rf "$staging"
    staging=
    backup=
    publish_cursor_skills "$target"
    echo "..Installed Cursor plugin: $name ($selection)"
    echo "..Reload Cursor, then type /poteto-mode or /setup-pstack."
done
