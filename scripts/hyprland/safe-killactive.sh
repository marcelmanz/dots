#!/usr/bin/env bash
if hyprctl activewindow -j | jq -e '.tags[]? | select(. == "locked")' >/dev/null; then
  notify-send "Window locked" "Press Mod+Tab to unlock it."
  exit 0
fi
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl dispatch killactive ""
else
  /usr/local/bin/hyprctl dispatch killactive ""
fi
