#!/usr/bin/env bash

if pkill -x bemenu >/dev/null 2>&1; then
	exit 0
fi

entries="Lock\nLock & Suspend\nLogout\nReboot\nShutdown\nSuspend"

selected=$(echo -e "$entries" | ~/scripts/themed-bemenu -p "power:" | awk '{print $0}')

[[ -z $selected ]] && exit

case "$selected" in
"Lock")
	hyprlock
	;;
"Lock & Suspend")
	hyprlock &
	disown && systemctl suspend
	;;
"Logout")
	hyprctl dispatch 'hl.dsp.exit()'
	;;
"Suspend")
	systemctl suspend
	;;
"Reboot")
	exec systemctl reboot
	;;
"Shutdown")
	exec systemctl poweroff -i
	;;
esac
