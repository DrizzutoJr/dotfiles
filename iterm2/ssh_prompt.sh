#!/bin/bash

read -r -p "Enter username: " USER
read -r -p "Enter IP/Server: " IP

# iTerm2 escape sequences for tab title and badge
# \033]0;TEXT\a sets the tab/window title
# \033]1337;SetBadgeFormat=BASE64TEXT\a sets the badge (must be base64-encoded)
BADGE_TEXT=$(echo -n "$IP" | base64)

# Change tab title
echo -ne "\033]0;$IP\a"

# Change badge
echo -ne "\033]1337;SetBadgeFormat=$BADGE_TEXT\a"


USER=${USER:-homelab}

echo "Connecting to $USER@$IP ..."
sleep 0.5

ssh -t "$USER@$IP" '
  # Ensure tmux is installed
  if ! command -v tmux &>/dev/null; then
    echo "tmux not found on remote host. Install with: sudo apt install tmux"
    exit 1
  fi

  # Session name based on IP
  SESSION="main"

  # Attach if exists, else create new session with horizontal split
  tmux attach -t "$SESSION" || tmux new-session -s "$SESSION" \; split-window -v \; select-pane -U
'