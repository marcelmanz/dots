#!/usr/bin/env bash

if ! command -v fzf &>/dev/null; then
	echo "fzf is not installed. Aborting."
	exit 1
fi

cd ~/notes/ || exit 1

# Find all matching TODO files, remove leading "./", and sort by year, month, then day (ascending)
todo_files=$(find . -maxdepth 1 -type f -name "TODO:????-??-??.md" | sed 's|^\./||' | sort)

# Select a file and preview it with fancy markdown rendering
selected_file=$(echo "$todo_files" | fzf --tac --height 40% --border --prompt="Select a TODO file: " \
	--preview="glow --width $(tput cols) --style dark {1}" --preview-window=right:50%)

if [ -n "$selected_file" ]; then
	nvim "$selected_file"
else
	echo "No file selected."
fi

cd - >/dev/null 2>&1
