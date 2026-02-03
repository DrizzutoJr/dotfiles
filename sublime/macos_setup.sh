#!/bin/bash

# shellcheck source=../_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"

echo ""
echo "Setting up Sublime Text config"
SUBLIME_USER_DIR="$HOME/Library/Application Support/Sublime Text/Packages/User"
create_symlink "$REPO_DIR/sublime/settings.json" "$SUBLIME_USER_DIR/Preferences.sublime-settings"
create_symlink "$REPO_DIR/sublime/CandyLand.tmTheme" "$SUBLIME_USER_DIR/CandyLand.tmTheme"
