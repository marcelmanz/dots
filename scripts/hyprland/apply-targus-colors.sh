#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "Hyprland instance not detected; ensure this runs inside Hyprland." >&2
    exit 1
fi

adjust() {
    local output=$1
    hyprctl keyword monitor "${output},gamma,1.05"
    hyprctl keyword monitor "${output},vibrance,0.08"
}

adjust DP-5
adjust DP-6
