#!/bin/bash

printf '%s\n' "$*" >> "$FAKE_CODEX_LOG"

if [[ -n "$FAKE_CODEX_FAIL_ON" && "$*" == *"$FAKE_CODEX_FAIL_ON"* ]]; then
    echo "fake Codex failure" >&2
    exit 1
fi

case "$1 $2 $3" in
    'plugin list --json')
        if [[ -f "$FAKE_CODEX_INSTALLED" ]]; then
            printf '{"installed":[{"pluginId":"mattpocock-skills@mattpocock"}]}\n'
        else
            printf '{"installed":[]}\n'
        fi
        ;;
    'plugin marketplace list')
        if [[ -f "$FAKE_CODEX_MARKETPLACE" ]]; then
            printf '{"marketplaces":[{"name":"mattpocock","root":"%s","marketplaceSource":{"sourceType":"git","source":"https://github.com/mattpocock/skills.git"}}]}\n' "$HOME/.codex/marketplace-root"
        else
            printf '{"marketplaces":[]}\n'
        fi
        ;;
    'plugin marketplace add')
        : > "$FAKE_CODEX_MARKETPLACE"
        mkdir -p "$HOME/.codex/marketplace-root"
        ref=
        while (($#)); do
            if [[ "$1" == --ref ]]; then
                ref="$2"
                break
            fi
            shift
        done
        printf '[marketplaces.mattpocock]\nsource_type = "git"\nsource = "https://github.com/mattpocock/skills.git"\n' > "$HOME/.codex/config.toml"
        if [[ -n "$ref" ]]; then
            printf 'ref = "%s"\n' "$ref" >> "$HOME/.codex/config.toml"
        fi
        printf '{"marketplaceName":"mattpocock","alreadyAdded":false}\n'
        ;;
    'plugin marketplace remove')
        rm -rf "$HOME/.codex/marketplace-root"
        rm "$FAKE_CODEX_MARKETPLACE"
        : > "$HOME/.codex/config.toml"
        printf '{"marketplaceName":"mattpocock"}\n'
        ;;
    'plugin marketplace upgrade')
        printf '{"marketplaces":[]}\n'
        ;;
    'plugin add '*)
        : > "$FAKE_CODEX_INSTALLED"
        printf '{"pluginId":"mattpocock-skills@mattpocock"}\n'
        ;;
    *)
        echo "Unexpected Codex command: $*" >&2
        exit 1
        ;;
esac
