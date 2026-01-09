#!/usr/bin/env bash

work_dir=~/clones/work
base_url="https://bitbucket.org/worldsensing_traffic"

if [ ! -d "$work_dir" ]; then
	echo "Missing directory: $work_dir"
	exit 1
fi

repos=$(find -L "$work_dir" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort)

menu_cmd="$1"

if [ -z "$menu_cmd" ]; then
	selected=$(printf '%s\n' "$repos" | fzf --prompt="repo> " --height=40%)
else
	selected=$(printf '%s\n' "$repos" | bash -c "$menu_cmd")
fi

[ -z "$selected" ] && exit 0

url="$base_url/$selected/src/main/"

if command -v open &>/dev/null; then
	open "$url"
else
	xdg-open "$url"
fi
