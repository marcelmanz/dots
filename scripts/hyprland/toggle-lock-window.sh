#!/usr/bin/env bash
if hyprctl activewindow -j | jq -e '.tags[]? | select(. == "locked")' >/dev/null; then
	hyprctl dispatch 'hl.dsp.window.tag({action="remove",tag="locked"})'
else
	hyprctl dispatch 'hl.dsp.window.tag({action="add",tag="locked"})'
fi
