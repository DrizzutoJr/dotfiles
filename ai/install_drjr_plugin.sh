#!/bin/bash

# shellcheck source=_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"
set -e

marketplace="$REPO_DIR/ai/skills"
plugin_id=drjr-skills@drjr
version="$(yq -r '.version' "$marketplace/drjr-skills/.claude-plugin/plugin.json")"

claude_marketplaces="$(claude plugin marketplace list --json)" || {
    echo "! Could not list Claude Code marketplaces" >&2
    exit 1
}
claude_source="$(printf '%s\n' "$claude_marketplaces" | yq -r '.[] | select(.name == "drjr") | .path // .repo // ""')"
if [[ -n "$claude_source" && "$claude_source" != "$marketplace" ]]; then
    echo "! Claude Code marketplace drjr uses a different source: $claude_source" >&2
    exit 1
fi
if [[ -z "$claude_source" ]]; then
    claude plugin marketplace add "$marketplace" || {
        echo "! Could not add Claude Code marketplace drjr" >&2
        exit 1
    }
fi

codex_marketplaces="$(codex plugin marketplace list --json)" || {
    echo "! Could not list Codex marketplaces" >&2
    exit 1
}
codex_source="$(printf '%s\n' "$codex_marketplaces" | yq -r '.marketplaces[] | select(.name == "drjr") | .marketplaceSource.source // ""')"
if [[ -n "$codex_source" && "$codex_source" != "$marketplace" ]]; then
    echo "! Codex marketplace drjr uses a different source: $codex_source" >&2
    exit 1
fi
if [[ -z "$codex_source" ]]; then
    codex plugin marketplace add "$marketplace" --json >/dev/null || {
        echo "! Could not add Codex marketplace drjr" >&2
        exit 1
    }
fi

claude_plugins="$(claude plugin list --json)" || {
    echo "! Could not list Claude Code plugins" >&2
    exit 1
}
claude_version="$(printf '%s\n' "$claude_plugins" | yq -r '.[] | select(.id == "drjr-skills@drjr" and .scope == "user") | .version')"
if [[ -z "$claude_version" ]]; then
    claude plugin install "$plugin_id" --scope user --json >/dev/null || {
        echo "! Could not install Claude Code plugin $plugin_id" >&2
        exit 1
    }
elif [[ "$claude_version" != "$version" ]]; then
    claude plugin update "$plugin_id" --scope user --json >/dev/null || {
        echo "! Could not update Claude Code plugin $plugin_id" >&2
        exit 1
    }
fi

codex_plugins="$(codex plugin list --json)" || {
    echo "! Could not list Codex plugins" >&2
    exit 1
}
codex_version="$(printf '%s\n' "$codex_plugins" | yq -r '.installed[] | select(.pluginId == "drjr-skills@drjr") | .version')"
if [[ "$codex_version" != "$version" ]]; then
    codex plugin add "$plugin_id" --json >/dev/null || {
        echo "! Could not install Codex plugin $plugin_id" >&2
        exit 1
    }
fi

echo "..Installed local plugin $plugin_id ($version) for Claude Code and Codex"
