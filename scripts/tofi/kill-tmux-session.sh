#!/usr/bin/env bash

if pkill -x bemenu >/dev/null 2>&1; then
	exit 0
fi

entries="Kill Session\nDetach Session\nCancel"

selected=$(echo -e "$entries" | ~/scripts/themed-bemenu -p "tmux:" | awk '{print $1}')
first_word=$(echo $selected | awk '{print $1}' | tr '[:upper:]' '[:lower:]')

[[ -z $selected ]] && exit

case $first_word in
kill)
	tmux kill-session -t $(tmux display-message -p '#S')
	notify-send "tmux-menu" "Session killed"
	;;
detach)
	tmux detach
	notify-send "tmux-menu" "Session detached"
	;;
cancel)
	notify-send "tmux-menu" "Operation cancelled"
	;;
esac
