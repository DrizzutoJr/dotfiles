#!/bin/bash

# shellcheck source=_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"
set -e

echo ""
echo "Setting up AI agent config"

instructions="$REPO_DIR/ai/AGENTS.md"
create_symlink "$instructions" "$HOME/.claude/CLAUDE.md"
create_symlink "$instructions" "$HOME/.codex/AGENTS.md"

for legacy_name in skills commands; do
    legacy_target="$HOME/.claude/$legacy_name"
    if [[ ! -L "$legacy_target" ]]; then
        continue
    fi

    case "$(readlink "$legacy_target")" in
        */claude_code/"$legacy_name")
            backup_path="$(backup_target "$legacy_target")"
            echo "..Retired legacy link to $backup_path"
            if [[ "$legacy_name" == skills ]]; then
                mkdir -p "$legacy_target"
            fi
            ;;
    esac
done

if ! command -v yq >/dev/null 2>&1; then
    echo "! yq is required to read ai/plugins.yaml" >&2
    exit 1
fi
if ! command -v codex >/dev/null 2>&1; then
    echo "! Codex CLI is required to install declared plugins" >&2
    exit 1
fi

plugin_selection=pinned
if [[ "$NON_INTERACTIVE" != true ]]; then
    while true; do
        read -r -p "Install AI plugins from pinned refs or latest? [P/l] " answer || answer=pinned
        case "$answer" in
            ''|p|P|pinned|Pinned) break ;;
            l|L|latest|Latest) plugin_selection=latest; break ;;
            *) echo "Choose pinned or latest." >&2 ;;
        esac
    done
fi

manifest="$REPO_DIR/ai/plugins.yaml"
plugin_count="$(yq -r '.plugins | length' "$manifest")" || {
    echo "! Could not read plugin manifest: $manifest" >&2
    exit 1
}
if [[ ! "$plugin_count" =~ ^[1-9][0-9]*$ ]]; then
    echo "! Plugin manifest must contain at least one plugin" >&2
    exit 1
fi

marketplace_json="$(codex plugin marketplace list --json)" || {
    echo "! Could not list Codex marketplaces" >&2
    exit 1
}
installed_json="$(codex plugin list --json)" || {
    echo "! Could not list installed Codex plugins" >&2
    exit 1
}

codex_home="${CODEX_HOME:-$HOME/.codex}"
codex_config="$codex_home/config.toml"
marketplace_backup_dir=
marketplace_root=
marketplace_transition_active=false

backup_marketplace() {
    umask 077
    marketplace_backup_dir="$(mktemp -d "$codex_home/marketplace-backup.XXXXXX")" || return 1
    if ! cp -p "$codex_config" "$marketplace_backup_dir/config.toml" || ! cp -R "$marketplace_root" "$marketplace_backup_dir/root"; then
        echo "! Could not back up Codex marketplace state" >&2
        rm -rf "$marketplace_backup_dir"
        marketplace_backup_dir=
        return 1
    fi
    marketplace_transition_active=true
}

restore_marketplace() {
    local result=$?
    trap - EXIT
    if [[ "$marketplace_transition_active" == true ]]; then
        if [[ -e "$marketplace_root" ]]; then
            mv "$marketplace_root" "$marketplace_backup_dir/failed-root" || true
        fi
        if cp -R "$marketplace_backup_dir/root" "$marketplace_root" && cp -p "$marketplace_backup_dir/config.toml" "$codex_config"; then
            echo "! Restored the previous Codex marketplace; backup: $marketplace_backup_dir" >&2
        else
            echo "! Could not fully restore the Codex marketplace; backup: $marketplace_backup_dir" >&2
        fi
    fi
    exit "$result"
}
trap restore_marketplace EXIT

for ((plugin_index=0; plugin_index<plugin_count; plugin_index++)); do
    agent="$(yq -r ".plugins[$plugin_index].agent" "$manifest")"
    name="$(yq -r ".plugins[$plugin_index].name" "$manifest")"
    marketplace="$(yq -r ".plugins[$plugin_index].marketplace" "$manifest")"
    source="$(yq -r ".plugins[$plugin_index].source" "$manifest")"
    ref="$(yq -r ".plugins[$plugin_index].ref" "$manifest")"

    if [[ "$agent" != codex || -z "$name" || "$name" == null || -z "$marketplace" || "$marketplace" == null || -z "$source" || "$source" == null || -z "$ref" || "$ref" == null ]]; then
        echo "! Invalid plugin declaration at index $plugin_index" >&2
        exit 1
    fi

    existing_source="$(printf '%s\n' "$marketplace_json" | PLUGIN_MARKETPLACE="$marketplace" yq -r '.marketplaces[] | select(.name == strenv(PLUGIN_MARKETPLACE)) | .marketplaceSource.source')" || {
        echo "! Could not read Codex marketplace list" >&2
        exit 1
    }
    marketplace_root="$(printf '%s\n' "$marketplace_json" | PLUGIN_MARKETPLACE="$marketplace" yq -r '.marketplaces[] | select(.name == strenv(PLUGIN_MARKETPLACE)) | .root')" || {
        echo "! Could not read Codex marketplace root" >&2
        exit 1
    }
    selector="$name@$marketplace"
    installed_ids="$(printf '%s\n' "$installed_json" | yq -r '.installed[].pluginId')" || {
        echo "! Could not read Codex plugin list" >&2
        exit 1
    }
    already_installed=false
    while IFS= read -r installed_id; do
        if [[ "$installed_id" == "$selector" ]]; then
            already_installed=true
            break
        fi
    done <<< "$installed_ids"

    if [[ -n "$existing_source" && "$existing_source" != "$source" ]]; then
        echo "! Codex marketplace $marketplace uses a different source: $existing_source" >&2
        exit 1
    fi

    marketplace_changed=false
    if [[ -z "$existing_source" ]]; then
        if [[ "$plugin_selection" == pinned ]]; then
            codex plugin marketplace add "$source" --ref "$ref" --json >/dev/null || {
                echo "! Could not add pinned Codex marketplace $marketplace" >&2
                exit 1
            }
        else
            codex plugin marketplace add "$source" --json >/dev/null || {
                echo "! Could not add latest Codex marketplace $marketplace" >&2
                exit 1
            }
        fi
        marketplace_changed=true
    else
        if [[ ! -f "$codex_config" || ! -d "$marketplace_root" ]]; then
            echo "! Codex marketplace $marketplace has missing local state" >&2
            exit 1
        fi
        current_ref="$(PLUGIN_MARKETPLACE="$marketplace" yq -p=toml -oy -r '.marketplaces[strenv(PLUGIN_MARKETPLACE)].ref // ""' "$codex_config")" || {
            echo "! Could not read Codex marketplace ref" >&2
            exit 1
        }
        desired_ref=
        if [[ "$plugin_selection" == pinned ]]; then
            desired_ref="$ref"
        fi
        if [[ "$current_ref" != "$desired_ref" ]]; then
            backup_marketplace || exit 1
            codex plugin marketplace remove "$marketplace" --json >/dev/null || {
                echo "! Could not remove prior Codex marketplace $marketplace" >&2
                exit 1
            }
            if [[ "$plugin_selection" == pinned ]]; then
                codex plugin marketplace add "$source" --ref "$ref" --json >/dev/null || {
                    echo "! Could not switch Codex marketplace $marketplace to pinned ref" >&2
                    exit 1
                }
            else
                codex plugin marketplace add "$source" --json >/dev/null || {
                    echo "! Could not switch Codex marketplace $marketplace to latest" >&2
                    exit 1
                }
            fi
            marketplace_changed=true
        elif [[ "$plugin_selection" == latest ]]; then
            backup_marketplace || exit 1
            codex plugin marketplace upgrade "$marketplace" --json >/dev/null || {
                echo "! Could not refresh Codex marketplace $marketplace" >&2
                exit 1
            }
        fi
    fi

    if [[ "$already_installed" == true && "$plugin_selection" == pinned && "$marketplace_changed" == false ]]; then
        echo "..Codex plugin already installed: $selector"
        continue
    fi

    codex plugin add "$selector" --json >/dev/null || {
        echo "! Could not install Codex plugin $selector" >&2
        exit 1
    }
    echo "..Installed Codex plugin: $selector ($plugin_selection)"
    if [[ "$marketplace_transition_active" == true ]]; then
        marketplace_transition_active=false
        rm -rf "$marketplace_backup_dir"
        marketplace_backup_dir=
    fi
done
