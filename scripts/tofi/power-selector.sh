#!/usr/bin/env bash

if pgrep -x "tofi" >/dev/null; then
	pkill tofi
fi

entries="Lock\nLock & Suspend\nLogout\nReboot\nShutdown\nSuspend"

selected=$(echo -e "$entries" | tofi --width 250 --height 270 | awk '{print $0}')

[[ -z $selected ]] && exit

case "$selected" in
"Lock")
	gammastep -l 0:0 -o -b 0.1:0.1 &
	hyprlock && killall gammastep
	;;
"Lock & Suspend")
	hyprlock &
	disown && systemctl suspend
	;;
"Logout")
	hyprctl dispatch exit
	;;
"Suspend")
	exec systemctl suspend
	;;
"Reboot")
	exec systemctl reboot
	;;
"Shutdown")
	exec systemctl poweroff -i
	;;
esac

