#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

case "${1:-}" in
    --remote)
        shift
        exec "$script_dir/create-remote-session.sh" "${1:-}"
        ;;
    -a|--attach)
        exec "$script_dir/attach-session.sh"
        ;;
esac

if [ -n "${1:-}" ]; then
    case "$1" in
        *://*|*@*:*|*.git)
            exec "$script_dir/create-clone.sh" "$1"
            ;;
    esac
    selection=$(printf '%s\n' "$1" | sed "s|^$HOME/||")
else
    dirs=$(find "$HOME/clones" -mindepth 2 -maxdepth 2 -type d -print0 | tr '\0' '\n' | sed "s|^$HOME/||")
    selection=$(printf '%s\n' "$dirs" | fzf)
fi

if [ -n "${selection:-}" ]; then
    selection="$HOME/$selection"
    session=$(basename "$selection" |
        tr '[:upper:]' '[:lower:]' |
        tr -c '[:alnum:]_' '_' |
        sed 's/_\+/_/g; s/^_//; s/_$//')
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
