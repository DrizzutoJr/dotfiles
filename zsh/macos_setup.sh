#!/bin/bash

# shellcheck source=../_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"

echo ""
echo "Setting up zsh"
echo "..Changing shell to zsh"
chsh -s /bin/zsh

echo "..Setting up zsh config"
create_symlink "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"
