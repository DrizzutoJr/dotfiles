#!/bin/bash

if [[ "$1" == clone && "$2" == --quiet && "$3" == https://github.com/michael-denyer/pstack-claude.git ]]; then
    exec /usr/bin/git clone --quiet "$FAKE_PSTACK_SOURCE" "$4"
fi
if [[ "$1" == -C && "$3" == checkout && "$4" == --detach && "$5" == --quiet && "$6" == 24c96b1eed2b07c62d0f88f0764a2954ed1d911a ]]; then
    initial_ref="$(/usr/bin/git -C "$2" rev-list --max-parents=0 HEAD)"
    exec /usr/bin/git -C "$2" checkout --detach --quiet "$initial_ref"
fi
exec /usr/bin/git "$@"
