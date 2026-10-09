#!/bin/bash

printf '%s\n' "$*" >> "$FAKE_CODEX_LOG"

if [[ -n "$FAKE_CODEX_FAIL_ON" && "$*" == *"$FAKE_CODEX_FAIL_ON"* ]]; then
    echo "fake Codex failure" >&2
    exit 1
fi

write_config() {
    mkdir -p "$HOME/.codex"
    : > "$HOME/.codex/config.toml"
    if [[ -f "$FAKE_CODEX_MARKETPLACE" ]]; then
        printf '[marketplaces.mattpocock]\nsource_type = "git"\nsource = "https://github.com/mattpocock/skills.git"\n' >> "$HOME/.codex/config.toml"
        matt_ref="$(cat "$FAKE_CODEX_MARKETPLACE")"
        [[ -z "$matt_ref" ]] || printf 'ref = "%s"\n' "$matt_ref" >> "$HOME/.codex/config.toml"
    fi
    if [[ -f "$FAKE_CODEX_MARKETPLACE.pstack" ]]; then
        printf '[marketplaces.pstack-claude]\nsource_type = "git"\nsource = "https://github.com/michael-denyer/pstack-claude.git"\n' >> "$HOME/.codex/config.toml"
        pstack_ref="$(cat "$FAKE_CODEX_MARKETPLACE.pstack")"
        [[ -z "$pstack_ref" ]] || printf 'ref = "%s"\n' "$pstack_ref" >> "$HOME/.codex/config.toml"
    fi
}

case "$1 $2 $3" in
    'plugin list --json')
        plugins=
        if [[ -f "$FAKE_CODEX_INSTALLED" ]]; then
            plugins='{"pluginId":"mattpocock-skills@mattpocock"}'
        fi
        if [[ -f "$FAKE_CODEX_INSTALLED.pstack" ]]; then
            [[ -z "$plugins" ]] || plugins+=,
            plugins+='{"pluginId":"pstack@pstack-claude"}'
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
        if [[ -f "$FAKE_CODEX_MARKETPLACE.pstack" ]]; then
            [[ -z "$marketplaces" ]] || marketplaces+=,
            marketplaces+="{\"name\":\"pstack-claude\",\"root\":\"$HOME/.codex/pstack-marketplace-root\",\"marketplaceSource\":{\"sourceType\":\"git\",\"source\":\"https://github.com/michael-denyer/pstack-claude.git\"}}"
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
        if [[ "$4" == *pstack-claude.git ]]; then
            state="$FAKE_CODEX_MARKETPLACE.pstack"
            root="$HOME/.codex/pstack-marketplace-root"
            name=pstack-claude
        else
            state="$FAKE_CODEX_MARKETPLACE"
            root="$HOME/.codex/marketplace-root"
            name=mattpocock
        fi
        mkdir -p "$root"
        ref=
        while (($#)); do
            if [[ "$1" == --ref ]]; then
                ref="$2"
                break
            fi
            shift
        done
        printf '%s\n' "$ref" > "$state"
        write_config
        printf '{"marketplaceName":"%s","alreadyAdded":false}\n' "$name"
        ;;
    'plugin marketplace remove')
        if [[ "$4" == pstack-claude ]]; then
            rm -rf "$HOME/.codex/pstack-marketplace-root"
            rm "$FAKE_CODEX_MARKETPLACE.pstack"
        else
            rm -rf "$HOME/.codex/marketplace-root"
            rm "$FAKE_CODEX_MARKETPLACE"
        fi
        write_config
        printf '{"marketplaceName":"%s"}\n' "$4"
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
        if [[ "$3" == pstack@pstack-claude ]]; then
            : > "$FAKE_CODEX_INSTALLED.pstack"
        else
            : > "$FAKE_CODEX_INSTALLED"
        fi
        printf '{"pluginId":"%s"}\n' "$3"
        ;;
    *)
        echo "Unexpected Codex command: $*" >&2
        exit 1
        ;;
esac
