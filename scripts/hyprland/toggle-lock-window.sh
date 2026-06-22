#!/usr/bin/env bash
if hyprctl activewindow -j | jq -e '.tags[]? | select(. == "locked")' >/dev/null; then
	hyprctl dispatch -- tagwindow -locked activewindow
else
	hyprctl dispatch -- tagwindow +locked activewindow
fi
