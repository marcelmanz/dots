#!/usr/bin/env bash

module_name="projectw"
icon="󰍹"

running() {
	pgrep -f projectw.py >/dev/null
}

print_status() {
	if running; then
		ironbar style add-class "$module_name" enabled >/dev/null 2>&1
	else
		ironbar style remove-class "$module_name" enabled >/dev/null 2>&1
	fi

	echo "$icon"
}

toggle() {
	if running; then
		pkill -f projectw.py 2>/dev/null
		status="projectw disabled"
	else
		systemd-run --user --scope --quiet projectw >/dev/null 2>&1 & disown
		status="projectw enabled"
	fi

	sleep 0.5
	print_status >/dev/null
	notify-send -t 1500 -a "projectw" -h string:x-canonical-private-synchronous:projectw "$icon  $status"
}

if [ "$1" = "toggle" ]; then
	toggle
	exit
fi

while true; do
	print_status
	sleep 5
done
