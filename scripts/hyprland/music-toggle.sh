#!/usr/bin/env bash

bar="main"

ostui_shown() {
	hyprctl clients -j | jaq -e '[.[] | select(.class == "ostui" and (.workspace.name | startswith("special:") | not))] | length > 0' >/dev/null
}

if [ "$1" = "hide" ] || { [ -z "$1" ] && ostui_shown; }; then
	pypr hide ostui
	ironbar bar "$bar" hide-popup >/dev/null
	hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null
else
	pypr show ostui
	ironbar bar "$bar" show-popup music >/dev/null
	hyprctl dispatch 'hl.dsp.submap("music")' >/dev/null
fi
