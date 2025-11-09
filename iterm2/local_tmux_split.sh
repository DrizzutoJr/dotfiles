#!/bin/bash

# Full path to tmux (adjust if needed)
TMUX=/opt/homebrew/bin/tmux

# Name of the session
SESSION="local_split"

# Check if session exists
if ! $TMUX has-session -t "$SESSION" 2>/dev/null; then
  # Session doesn't exist → create it with horizontal split, top pane active
  $TMUX new-session -s "$SESSION" -n main \; \
    split-window -v -c "#{pane_current_path}" \; \
    select-pane -U
fi

# Attach to the session (foreground)
$TMUX attach -t "$SESSION"