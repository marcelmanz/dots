#!/usr/bin/env bash

sessions=$(tmux list-sessions -F "#{session_name}")
current_session=$(tmux display-message -p "#{session_name}")

for session in $sessions; do
	if [[ "$session" == "$current_session" ]]; then
		continue
	fi
	echo "$session"
done | ~/.nix-profile/bin/tofi --width 350 --height 210 | xargs tmux switch-client -t
