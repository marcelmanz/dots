#!/usr/bin/env bash

bar="main"
bar_height=35

if [ "$(ironbar bar "$bar" get-visible)" = "true" ]; then
	visible=false
else
	visible=true
fi

ironbar bar "$bar" set-visible "$visible" >/dev/null

if [ "$visible" = "true" ]; then
	bottom=$bar_height
	status="Bar shown"
else
	bottom=5
	status="Bar hidden"
fi

hyprctl eval "hl.config({ general = { gaps_out = { top = 5, right = 5, bottom = $bottom, left = 5 } } })" >/dev/null
notify-send -t 1500 -a "Bar" -i "$HOME/clones/own/dots/.config/hypr/hyprland.svg" -h string:x-canonical-private-synchronous:bar "$status"
