#!/usr/bin/env bash

set -eu

menu_cmd="fzf"
source="github"

while [ $# -gt 0 ]; do
    case "$1" in
    --menu)
        menu_cmd="$2"
        shift 2
        ;;
    --source)
        source="$2"
        shift 2
        ;;
    *)
        echo "Unknown argument: $1" >&2
        exit 1
        ;;
    esac
done

menu() {
    sh -c "$menu_cmd"
}

github_list() {
    cache="${XDG_CACHE_HOME:-$HOME/.cache}/repos-github"

    if [ ! -f "$cache" ] || [ "$(find "$cache" -mmin +5)" ]; then
        gh api user/repos --paginate -q '.[].full_name' >"$cache"
    fi

    cat "$cache"
}

github_open() {
    gh repo view "$1" -w
}

run() {
    case "$source" in
    github)
        repo=$(github_list | menu)
        [ -n "$repo" ] && github_open "$repo"
        ;;
    *)
        echo "Unknown source: $source" >&2
        exit 1
        ;;
    esac
}

run
