#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
clones_dir="$HOME/clones"

url="${1:-}"

if [ -z "$url" ]; then
    existing=$(find "$clones_dir" -mindepth 2 -maxdepth 2 -type d -print0 |
        tr '\0' '\n' | sed "s|^$HOME/||")
    selection=$(printf '%s\n' "$existing" |
        fzf --print-query --prompt='pick existing or clone url> ' |
        tail -n1)
    [ -z "${selection:-}" ] && exit 0

    if [ -d "$HOME/$selection" ]; then
        exec "$script_dir/create-session.sh" "$HOME/$selection"
    fi
    url="$selection"
fi

repo=$(basename "$url" .git)

groups=$(find "$clones_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
group=$(printf '%s\n' "$groups" |
    fzf --print-query --prompt='clone into group> ' |
    tail -n1)
[ -z "${group:-}" ] && exit 0

target="$clones_dir/$group/$repo"

if [ ! -d "$target" ]; then
    mkdir -p "$(dirname "$target")"
    git clone "$url" "$target"
fi

exec "$script_dir/create-session.sh" "$target"
