#!/usr/bin/env bash
set -euo pipefail

dirs=$(find "$HOME/clones" -mindepth 2 -maxdepth 2 -type d -print0 | tr '\0' '\n' | sed "s|^$HOME/||")
selection=$(printf '%s\n' "$dirs" | fzf)

if [ -n "${selection:-}" ]; then
    selection="$HOME/$selection"
    session=$(basename "$selection")
    if ! tmux has-session -t "$session" 2>/dev/null; then
        tmux new-session -ds "$session" -c "$selection"
        tmux send-keys -t "$session" nvim C-m
    fi
    if [ -n "${TMUX-}" ]; then
        tmux switch-client -t "$session"
    else
        tmux attach -t "$session"
    fi
fi
