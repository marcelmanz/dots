#!/usr/bin/env bash

if [ $# -gt 1 ]; then
	echo "Usage: gste [path]"
	exit 1
fi

path=${1:-.}

cd "$path" || exit

git_root=$(git rev-parse --show-toplevel) || exit

tmpfile=$(mktemp)

git status --porcelain >"$tmpfile"

nvim "$tmpfile"

cd "$git_root" || exit

mapfile -t files < <(sed 's/^...//' "$tmpfile" | sed '/^$/d')

[ ${#files[@]} -eq 0 ] && exit 0

nvim "${files[@]}"
