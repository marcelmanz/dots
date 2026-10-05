#!/usr/bin/env bash
set -euo pipefail

addr=$(hyprctl -j activewindow | jq -r '.address')
[ -z "$addr" ] && {
    echo "No active window address"
    exit 1
}

wsid=$(hyprctl -j activeworkspace | jq -r '.id')

hyprctl dispatch "hl.dsp.window.move({workspace=\"special:termhide\",window=\"address:$addr\",silent=true})"

trap 'hyprctl dispatch "hl.dsp.window.move({workspace=$wsid,window=\"address:$addr\",silent=true})"; hyprctl dispatch "hl.dsp.focus({window=\"address:$addr\"})"' EXIT

neovide "$@"
