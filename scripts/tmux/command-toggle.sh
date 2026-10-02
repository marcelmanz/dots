#!/usr/bin/env bash
# Toggle a command pane in/out of the current window without killing it.
# Usage: command-toggle.sh <command> <top|bottom|left|right>

cmd="${1:?usage: command-toggle.sh <command> <top|bottom|left|right>}"
pos="${2:?usage: command-toggle.sh <command> <top|bottom|left|right>}"
id=$(printf '%s' "${cmd}_${pos}" | tr -c 'a-zA-Z0-9_' '_')
opt="@toggle_${id}"

case "$pos" in
top) axis=-v; before=-b ;;
bottom) axis=-v; before= ;;
left) axis=-h; before=-b ;;
right) axis=-h; before= ;;
*)
	echo "position must be top, bottom, left or right" >&2
	exit 1
	;;
esac

pane_id=$(tmux list-panes -a -F "#{pane_id} #{${opt}}" | awk '$2=="1"{print $1; exit}')

if [ -z "$pane_id" ]; then
	pane_id=$(tmux split-window $axis $before -f -p 50 -c '#{pane_current_path}' -P -F '#{pane_id}' "$cmd")
	tmux set-option -p -t "$pane_id" "$opt" 1
	exit 0
fi

current_window=$(tmux display-message -p '#{session_name}:#{window_index}')
pane_window=$(tmux display-message -p -t "$pane_id" '#{session_name}:#{window_index}')

if [ "$current_window" = "$pane_window" ]; then
	tmux break-pane -d -n "toggle-${id}" -s "$pane_id"
else
	tmux join-pane $axis $before -f -p 50 -s "$pane_id"
fi
