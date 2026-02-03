#!/bin/bash

# shellcheck source=../_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"

echo ""
echo "Setting up bash profile"
create_symlink "$REPO_DIR/bash/bash_profile" "$HOME/.bash_profile"
