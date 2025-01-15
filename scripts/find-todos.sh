#!/usr/bin/env bash

if ! command -v fzf &>/dev/null; then
	echo "fzf is not installed. Aborting."
	exit 1
fi

cd ~/notes/ || exit 1

todo_files=$(find . -maxdepth 1 -type f -name "TODO:??-??-????.md" | sort -b -t- -k2,2 -k1,1)

# Classic fzf file selection
# selected_file=$(echo "$todo_files" | fzf --height 40% --border --prompt="Select a TODO file: ")

# Select a file and preview it with fancy markdown rendering
selected_file=$(echo "$todo_files" | fzf --height 40% --border --prompt="Select a TODO file: " \
	--preview="glow --width $(tput cols) --style dark {1}" --preview-window=right:50%) # Use glow for markdown preview
# --preview="bat --color always {1}" --preview-window=right:50%) # Use bat for syntax highlighting

if [ -n "$selected_file" ]; then
	nvim "$selected_file"
else
	echo "No file selected."
fi

cd - >/dev/null 2>&1
