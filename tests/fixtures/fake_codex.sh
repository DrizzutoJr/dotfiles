#!/bin/bash

printf '%s\n' "$*" >> "$FAKE_CODEX_LOG"

if [[ -n "$FAKE_CODEX_FAIL_ON" && "$*" == *"$FAKE_CODEX_FAIL_ON"* ]]; then
    echo "fake Codex failure" >&2
    exit 1
fi

case "$1 $2 $3" in
    'plugin list --json')
        plugins=
        if [[ -f "$FAKE_CODEX_INSTALLED" ]]; then
            plugins='{"pluginId":"mattpocock-skills@mattpocock"}'
        fi
        if [[ -f "$HOME/.codex/drjr-installed" ]]; then
            [[ -z "$plugins" ]] || plugins+=,
            plugins+="{\"pluginId\":\"drjr-skills@drjr\",\"version\":\"$(cat "$HOME/.codex/drjr-installed")\"}"
        fi
        printf '{"installed":[%s]}\n' "$plugins"
        ;;
    'plugin marketplace list')
        marketplaces=
        if [[ -f "$FAKE_CODEX_MARKETPLACE" ]]; then
            marketplaces="{\"name\":\"mattpocock\",\"root\":\"$HOME/.codex/marketplace-root\",\"marketplaceSource\":{\"sourceType\":\"git\",\"source\":\"https://github.com/mattpocock/skills.git\"}}"
        fi
        if [[ -f "$HOME/.codex/drjr-marketplace" ]]; then
            [[ -z "$marketplaces" ]] || marketplaces+=,
            marketplaces+="{\"name\":\"drjr\",\"root\":\"$(cat "$HOME/.codex/drjr-marketplace")\",\"marketplaceSource\":{\"sourceType\":\"local\",\"source\":\"$(cat "$HOME/.codex/drjr-marketplace")\"}}"
        fi
        printf '{"marketplaces":[%s]}\n' "$marketplaces"
        ;;
    'plugin marketplace add')
        if [[ "$4" == */ai/skills ]]; then
            mkdir -p "$HOME/.codex"
            printf '%s\n' "$4" > "$HOME/.codex/drjr-marketplace"
            printf '{"marketplaceName":"drjr","alreadyAdded":false}\n'
            exit 0
        fi
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
        if [[ "$3" == drjr-skills@drjr ]]; then
            printf '0.1.0\n' > "$HOME/.codex/drjr-installed"
            printf '{"pluginId":"drjr-skills@drjr","version":"0.1.0"}\n'
            exit 0
        fi
        : > "$FAKE_CODEX_INSTALLED"
        printf '{"pluginId":"mattpocock-skills@mattpocock"}\n'
        ;;
    *)
        echo "Unexpected Codex command: $*" >&2
        exit 1
        ;;
esac
