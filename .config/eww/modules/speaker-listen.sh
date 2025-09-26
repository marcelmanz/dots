#!/usr/bin/env bash

# Function to get current speaker state (default sink)
get_speaker_state() {
    mute_line=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)
    vol_line=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | head -n1)

    if echo "$mute_line" | grep -q ": yes"; then
        volume="off"
        icon=""
    else
        vol_percent=$(echo "$vol_line" | grep -oE "[0-9]+%" | head -n1 | tr -d '%')
        vol_percent=${vol_percent:-0}
        if [ "$vol_percent" -gt 66 ]; then
            icon=""
        elif [ "$vol_percent" -gt 33 ]; then
            icon=""
        elif [ "$vol_percent" -gt 0 ]; then
            icon=""
        else
            icon=""
        fi
        volume="${vol_percent}%"
    fi
    echo "{\"content\": \"$volume\", \"icon\": \"$icon \"}"
}

# Output initial state
get_speaker_state

# Listen for PulseAudio/PipeWire events and output state on relevant changes
# React to default-device changes and device add/remove, not just volume changes
pactl subscribe | while read -r event; do
    # Examples:
    #  - Event 'change' on sink #42
    #  - Event 'new' on sink #63
    #  - Event 'remove' on sink #61
    #  - Event 'change' on server
    #  - Event 'change' on card #5
    if echo "$event" | grep -E "on (sink|server|card)" >/dev/null; then
        get_speaker_state
    fi
done
