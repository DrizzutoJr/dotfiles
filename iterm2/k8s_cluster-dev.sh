#!/bin/bash
set -euo pipefail

# Ensure Homebrew-installed binaries are in PATH (macOS)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Default username
DEFAULT_USER="homelab"

# Prompt for username
read -p "Enter SSH username ($DEFAULT_USER) > " SSH_USER
SSH_USER=${SSH_USER:-$DEFAULT_USER}

# Prompt for password (optional, will fallback to key auth). Hidden input.
read -s -p "Enter SSH password (leave blank for key auth) > " SSH_PASS
echo ""

# Name of the tmux session
SESSION="multi_ssh_$(date +%Y%m%d_%H%M%S)"

# IPs to connect
IPS=("192.168.1.100" "192.168.1.101" "192.168.1.103")

# Detect sshpass availability
if command -v sshpass >/dev/null 2>&1; then
  SSHPASS_AVAILABLE=1
else
  SSHPASS_AVAILABLE=0
fi

# Start a new tmux session detached
tmux new-session -d -s "$SESSION"

# Helper to send command into a pane with secure SSHPASS export when needed.
# Arguments: pane-target ip
send_ssh_to_pane() {
  local pane_target="$1"
  local ip="$2"

  if [ -n "$SSH_PASS" ] && [ "$SSHPASS_AVAILABLE" -eq 1 ]; then
    # Shell-escape the password so special chars are safe inside the pane command
    ESCAPED_PASS=$(printf '%q' "$SSH_PASS")
    # Export and run sshpass in the same command so SSHPASS is available in that shell only
    tmux send-keys -t "$pane_target" "export SSHPASS=$ESCAPED_PASS; sshpass -e ssh -o StrictHostKeyChecking=no $SSH_USER@$ip" C-m
  else
    if [ -n "$SSH_PASS" ] && [ "$SSHPASS_AVAILABLE" -eq 0 ]; then
      tmux send-keys -t "$pane_target" "echo '⚠️ sshpass not found; falling back to key auth'; ssh -o StrictHostKeyChecking=no $SSH_USER@$ip" C-m
    else
      tmux send-keys -t "$pane_target" "ssh -o StrictHostKeyChecking=no $SSH_USER@$ip" C-m
    fi
  fi
}

# Pane 0 (first IP)
send_ssh_to_pane "$SESSION:0.0" "${IPS[0]}"

# Pane 1 (create vertical split under pane 0)
tmux split-window -v -t "$SESSION:0.0"
send_ssh_to_pane "$SESSION:0.1" "${IPS[1]}"

# Pane 2 (create vertical split under pane 1)
tmux split-window -v -t "$SESSION:0.1"
send_ssh_to_pane "$SESSION:0.2" "${IPS[2]}"

# Make panes evenly stacked
tmux select-layout -t "$SESSION" even-vertical

# Attach to the session
tmux attach-session -t "$SESSION"
