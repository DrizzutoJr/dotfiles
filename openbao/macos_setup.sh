#!/bin/bash

# shellcheck source=../_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"

echo ""
echo "Setting up openbao"

echo "..Setting up openbao aliases"
create_symlink "$REPO_DIR/openbao/aliases-homelab.sh" "$HOME/.openbao_aliases.sh"
