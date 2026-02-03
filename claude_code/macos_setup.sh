#!/bin/bash

# shellcheck source=../_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"

echo ""
echo "Setting up Claude Code config"
CLAUDE_DIR="$HOME/.claude"

# If ~/.claude is a symlink (from old setup), remove it
if [[ -L "$CLAUDE_DIR" ]]; then
    echo "..Removing old symlink: $CLAUDE_DIR"
    rm "$CLAUDE_DIR"
fi

# Create ~/.claude directory if it doesn't exist
if [[ ! -d "$CLAUDE_DIR" ]]; then
    echo "..Creating directory: $CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR"
fi

create_symlink "$REPO_DIR/claude_code/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
create_dir_symlink "$REPO_DIR/claude_code/skills" "$CLAUDE_DIR/skills"
create_dir_symlink "$REPO_DIR/claude_code/commands" "$CLAUDE_DIR/commands"
