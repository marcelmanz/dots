#!/usr/bin/env bash

# pkill tofi or
if pgrep -x "tofi" >/dev/null; then
	pkill tofi
fi

entries="Kill Session\nDetach Session\nCancel"

selected=$(echo -e "$entries" | ~/.nix-profile/bin/tofi --prompt-text "tmux> " --width 250 --height 160 | awk '{print $1}')
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
