#!/usr/bin/env bash
set -u

sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
if [ -z "$sig" ]; then
  sig="$(hyprctl instances -j | jq -r '.[0].instance' 2>/dev/null || true)"
fi

socket="$XDG_RUNTIME_DIR/hypr/$sig/.socket2.sock"

socat - UNIX-CONNECT:"$socket" | while read -r event; do
  case "$event" in
  openwindow\>\>*)
    HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl dispatch fullscreen 0
    ;;
  esac
done
