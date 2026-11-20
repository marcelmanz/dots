#!/usr/bin/env bash

ostui_shown() {
	hyprctl clients -j | jaq -e '[.[] | select(.class == "ostui" and (.workspace.name | startswith("special:") | not))] | length > 0' >/dev/null
}

if [ "$1" = "hide" ] || { [ -z "$1" ] && ostui_shown; }; then
	pypr hide ostui
	~/scripts/hyprland/media close
	hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null
else
	pypr show ostui
	~/scripts/hyprland/media open
	hyprctl dispatch 'hl.dsp.submap("music")' >/dev/null
fi
