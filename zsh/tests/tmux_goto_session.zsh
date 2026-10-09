#!/bin/zsh

set -eu

fpath=("${0:A:h:h}/functions" $fpath)
autoload -Uz _tmux_goto_session

test_log="$(mktemp)"
trap 'rm -f "$test_log"' EXIT

tty() {
  print -r -- "$current_tty"
}

tmux() {
  local socket="default"
  if [[ "$1" == -S ]]; then
    socket="$2"
    shift 2
  fi
  if [[ "$1" == display-message ]]; then
    print -r -- "$mock_pane_tty"
  else
    print -r -- "$1:$2:${+TMUX}:${+TMUX_PANE}:$socket" >> "$test_log"
  fi
}

assert_call() {
  local expected="$1"
  local actual="$(cat "$test_log")"
  if [[ "$actual" != "$expected" ]]; then
    print -u2 "expected: $expected"
    print -u2 "actual:   $actual"
    return 1
  fi
  : > "$test_log"
}

TMUX=/tmp/tmux-test/default,123,0
TMUX_PANE=%1
current_tty=/dev/ttys100
mock_pane_tty=/dev/ttys200
_tmux_goto_session code-project-1
assert_call 'attach-session:-t:0:0:/tmp/tmux-test/default'

mock_pane_tty="$current_tty"
_tmux_goto_session code-project-1
assert_call 'switch-client:-t:1:1:default'

mock_pane_tty=""
_tmux_goto_session code-project-1
assert_call 'attach-session:-t:0:0:/tmp/tmux-test/default'

TMUX=""
TMUX_PANE=""
_tmux_goto_session code-project-1
assert_call 'attach-session:-t:0:0:default'

print 'tmux session routing passed'
