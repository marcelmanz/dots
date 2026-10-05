#!/usr/bin/env bash
state=/tmp/hypr-touchpad-enabled
if [ -f "$state" ]; then
    enabled=false
    rm "$state"
else
    enabled=true
    touch "$state"
fi
hyprctl eval "hl.device({ name = \"synps/2-synaptics-touchpad\", enabled = $enabled })"
notify-send -t 1500 "Touchpad $enabled"
