#!/usr/bin/env bash

TARGET=$(tmux display-message -p "#{session_name}:#{window_index}")

tmux list-windows -F "#{window_index}" -t "${TARGET%:*}" |
	grep -v "^${TARGET#*:}$" |
	while read -r W; do
		tmux join-pane -s "${TARGET%:*}:${W}.0" -t "${TARGET}"
		tmux kill-window -t "${TARGET%:*}:${W}"
	done

tmux set-window-option -t "$TARGET" @exploded 0
