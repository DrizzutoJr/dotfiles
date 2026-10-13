#!/bin/bash

printf '%s\n' "$*" >> "$FAKE_CLAUDE_LOG"

if [[ -n "$FAKE_CLAUDE_FAIL_ON" && "$*" == *"$FAKE_CLAUDE_FAIL_ON"* ]]; then
    echo "fake Claude failure" >&2
    exit 1
fi

case "$1 $2 $3" in
    'plugin validate '*)
        ;;
    'plugin marketplace list')
        marketplaces=
        if [[ -f "$HOME/.claude/drjr-marketplace" ]]; then
            marketplaces="{\"name\":\"drjr\",\"source\":\"directory\",\"path\":\"$(cat "$HOME/.claude/drjr-marketplace")\"}"
        fi
        if [[ -f "$HOME/.claude/pstack-marketplace" ]]; then
            [[ -z "$marketplaces" ]] || marketplaces+=,
            marketplaces+="{\"name\":\"pstack-claude\",\"source\":\"directory\",\"path\":\"$(cat "$HOME/.claude/pstack-marketplace")\"}"
        fi
        printf '[%s]\n' "$marketplaces"
        ;;
    'plugin marketplace add')
        mkdir -p "$HOME/.claude"
        if [[ "$4" == */ai/skills ]]; then
            printf '%s\n' "$4" > "$HOME/.claude/drjr-marketplace"
        else
            printf '%s\n' "$4" > "$HOME/.claude/pstack-marketplace"
        fi
        ;;
    'plugin list --json')
        plugins=
        if [[ -f "$HOME/.claude/drjr-installed" ]]; then
            plugins="{\"id\":\"drjr-skills@drjr\",\"scope\":\"user\",\"version\":\"$(cat "$HOME/.claude/drjr-installed")\"}"
        fi
        if [[ -f "$HOME/.claude/pstack-installed" ]]; then
            [[ -z "$plugins" ]] || plugins+=,
            plugins+="{\"id\":\"pstack@pstack-claude\",\"scope\":\"user\",\"version\":\"$(cat "$HOME/.claude/pstack-installed")\"}"
        fi
        printf '[%s]\n' "$plugins"
        ;;
    'plugin install '*|'plugin update '*)
        if [[ "$3" == pstack@pstack-claude ]]; then
            printf '0.9.79\n' > "$HOME/.claude/pstack-installed"
        else
            printf '0.1.0\n' > "$HOME/.claude/drjr-installed"
        fi
        printf '{"outcome":"ok"}\n'
        ;;
    *)
        echo "Unexpected Claude command: $*" >&2
        exit 1
        ;;
esac
