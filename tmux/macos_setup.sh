#!/bin/bash

# shellcheck source=../_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"

echo ""
echo "Setting up tmux config"

if pgrep tmux > /dev/null; then
    echo "! Warning: tmux is currently running."
    if [[ "$NON_INTERACTIVE" == true ]]; then
        echo "..Skipping tmux config setup (non-interactive mode)"
        exit 0
    else
        read -p "Skip tmux setup? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "..Skipping tmux config setup"
            exit 0
        else
            echo "! Please quit tmux and run the script again." >&2
            exit 1
        fi
    fi
fi

create_symlink "$REPO_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
