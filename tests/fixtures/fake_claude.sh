#!/bin/bash

printf '%s\n' "$*" >> "$FAKE_CLAUDE_LOG"

if [[ -n "$FAKE_CLAUDE_FAIL_ON" && "$*" == *"$FAKE_CLAUDE_FAIL_ON"* ]]; then
    echo "fake Claude failure" >&2
    exit 1
fi

case "$1 $2 $3" in
    'plugin marketplace list')
        if [[ -f "$HOME/.claude/drjr-marketplace" ]]; then
            printf '[{"name":"drjr","source":"directory","path":"%s"}]\n' "$(cat "$HOME/.claude/drjr-marketplace")"
        else
            printf '[]\n'
        fi
        ;;
    'plugin marketplace add')
        mkdir -p "$HOME/.claude"
        printf '%s\n' "$4" > "$HOME/.claude/drjr-marketplace"
        ;;
    'plugin list --json')
        if [[ -f "$HOME/.claude/drjr-installed" ]]; then
            printf '[{"id":"drjr-skills@drjr","scope":"user","version":"%s"}]\n' "$(cat "$HOME/.claude/drjr-installed")"
        else
            printf '[]\n'
        fi
        ;;
    'plugin install '*|'plugin update '*)
        printf '0.1.0\n' > "$HOME/.claude/drjr-installed"
        printf '{"outcome":"ok"}\n'
        ;;
    *)
        echo "Unexpected Claude command: $*" >&2
        exit 1
        ;;
esac
