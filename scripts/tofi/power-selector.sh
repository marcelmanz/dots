#!/usr/bin/env bash

# pkill tofi or
if pgrep -x "tofi" >/dev/null; then
	pkill tofi
fi

Lock
Logout
Reboot
Shutdown
Suspend

entries="Lock\nLogout\nReboot\nShutdown\nSuspend"

selected=$(echo -e "$entries" | tofi --width 250 --height 210 | awk '{print $1}')

[[ -z $selected ]] && exit

case $selected in
Lock)
	hyprlock
	;;
Logout)
	hyprctl dispatch exit
	;;
Suspend)
	exec systemctl suspend
	;;
Reboot)
	exec systemctl reboot
	;;
Shutdown)
	exec systemctl poweroff -i
	;;
esac
