#!/usr/bin/env bash

SRC=$(tmux display-message -p "#{session_name}:#{window_index}")

tmux list-panes -t "$SRC" -F "#{pane_index}" |
	while read -r P; do
		tmux break-pane -d -s "${SRC}.${P}"
	done

tmux set-window-option -t "$SRC" @exploded 1
