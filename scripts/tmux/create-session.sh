#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n'
dirs=$(find ~/clones -mindepth 2 -maxdepth 2 -type d)
selection=$(printf '%s\n' $dirs | fzf)

if [ -n "$selection" ]; then
    session=$(basename "$selection")
    if ! tmux has-session -t "$session" 2>/dev/null; then
        tmux new-session -ds "$session" -c "$selection"
        tmux send-keys -t "$session" nvim C-m
    fi
    tmux attach -t "$session"
fi
