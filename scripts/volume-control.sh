#!/usr/bin/env bash

CACHE="$XDG_RUNTIME_DIR/volume-cache"

get_volume_fast() {
    if [[ -f "$CACHE" ]]; then
        cat "$CACHE"
    else
        pactl list sinks | grep -A15 "$(pactl get-default-sink)" | grep "Volume:" | head -1 | awk '{print $5}' | tr -d '%'
    fi
}

case "$1" in
    up)
        current=$(get_volume_fast)
        new=$((current + 5))
        [[ $new -gt 125 ]] && new=125
        echo "$new" | tee "$CACHE" > "$XDG_RUNTIME_DIR/wob-volume.sock"
        pamixer -i 5 --allow-boost --set-limit 125 &
        ;;
    down)
        current=$(get_volume_fast)
        new=$((current - 5))
        [[ $new -lt 0 ]] && new=0
        echo "$new" | tee "$CACHE" > "$XDG_RUNTIME_DIR/wob-volume.sock"
        pamixer -d 5 --allow-boost &
        ;;
esac
