#!/usr/bin/env bash
set -euo pipefail

addr=$(hyprctl -j activewindow | jq -r '.address')
[ -z "$addr" ] && {
    echo "No active window address"
    exit 1
}

wsid=$(hyprctl -j activeworkspace | jq -r '.id')

hyprctl dispatch movetoworkspacesilent special:termhide,address:$addr

trap 'hyprctl dispatch movetoworkspacesilent "$wsid",address:$addr; hyprctl dispatch focuswindow address:$addr' EXIT

neovide "$@"
