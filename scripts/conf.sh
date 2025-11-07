#!/usr/bin/env bash

CONFIG_PATH=$(find ~/.config -mindepth 1 -maxdepth 1 -printf '%f\t%p\n' |
	fzf --with-nth=1 --delimiter='\t' \
		--preview 'path=$(echo {} | cut -f2); if [ -d "$path" ]; then tree -L 2 "$path" 2>/dev/null | head -100; else bat --style=numbers --color=always "$path" 2>/dev/null || head -100 "$path"; fi' | cut -f2)

[ -z "$CONFIG_PATH" ] && {
	echo "No configuration selected."
	exit 1
}

if [ -d "$CONFIG_PATH" ]; then
	cd "$CONFIG_PATH" || exit
	nvim .
	cd - || exit
else
	nvim "$CONFIG_PATH"
fi
