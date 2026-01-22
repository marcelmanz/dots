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

if [ ! -s "$tmpfile" ]; then
	echo "Working tree clean"
	exit 0
fi

nvim "$tmpfile"

cd "$git_root" || exit

mapfile -t files < <(sed 's/^...//' "$tmpfile" | sed '/^$/d')
[ ${#files[@]} -eq 0 ] && exit 0

nvim \
	+"lua vim.fn.setqflist({}, 'r', { items = vim.tbl_map(function(f) return { filename = f } end, vim.fn.argv()) })" \
	+"copen" \
	"${files[@]}"
