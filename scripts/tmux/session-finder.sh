#!/usr/bin/env bash

sessions=($(tmux list-sessions -F "#{session_name}"))
current_session=$(tmux display-message -p "#{session_name}")

if ((${#sessions[@]} <= 1)); then
	notify-send "tmux" "No other sessions to switch to.\nCurrent session is '$current_session'."
	exit 0
fi

if ((${#sessions[@]} == 2)); then
	for session in "${sessions[@]}"; do
		if [[ "$session" != "$current_session" ]]; then
			tmux switch-client -t "$session"
			notify-send "tmux" "Automatically switched to session '$session'."
			exit 0
		fi
	done
fi

selected=$(for session in "${sessions[@]}"; do
	[[ "$session" == "$current_session" ]] && continue
	echo "$session"
done | fzf --prompt="Switch to tmux session: ")

if [[ -n "$selected" ]]; then
	tmux switch-client -t "$selected"
fi
