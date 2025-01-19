#!/usr/bin/env bash

prompt_text="Monitor to mirror: "

killall wl-mirror

selected_monitor=$(
	hyprctl monitors |
		grep 'Monitor' |
		awk '{print $2}' |
		tofi --prompt-text "$prompt_text"
)

if [ -z "$selected_monitor" ]; then
	exit 1
fi

wl-mirror "$selected_monitor"
