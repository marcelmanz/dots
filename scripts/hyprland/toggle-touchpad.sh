#!/usr/bin/env bash

module_name="touchpad"
state="$XDG_RUNTIME_DIR/hypr-touchpad-enabled"

if [ -f "$state" ]; then
	enabled=false
	icon="󰤳"
	status="Touchpad disabled"
	rm "$state"
	ironbar style remove-class "$module_name" enabled >/dev/null 2>&1
else
	enabled=true
	icon="󰟸"
	status="Touchpad enabled"
	touch "$state"
	ironbar style add-class "$module_name" enabled >/dev/null 2>&1
fi

hyprctl devices -j | jq -r '.mice[].name | select(endswith("-touchpad"))' | while read -r device; do
	hyprctl eval "hl.device({ name = \"$device\", enabled = $enabled })" >/dev/null
done

ironbar var set "$module_name" "$icon" >/dev/null 2>&1
notify-send -t 1500 -a "Touchpad" -h string:x-canonical-private-synchronous:touchpad "$icon  $status"
