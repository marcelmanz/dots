#!/usr/bin/env bash

# Function to get current microphone state
get_mic_state() {
    mute=$(pamixer --default-source --get-mute)
    if [ "$mute" = "true" ]; then
        volume="off"
        icon=" "
    else 
        volume="$(pamixer --default-source --get-volume)%"
        icon=""
    fi
    echo "{\"content\": \"$volume\", \"icon\": \"$icon\"}"
}

# Output initial state
get_mic_state

# Listen for PulseAudio/PipeWire events and output state on relevant changes
# React to default-device changes and device add/remove, not just volume changes
pactl subscribe | while read -r event; do
    # Examples:
    #  - Event 'change' on source #18
    #  - Event 'new' on source #21
    #  - Event 'remove' on source #19
    #  - Event 'change' on server
    #  - Event 'change' on card #5
    if echo "$event" | grep -E "on (source|server|card)" >/dev/null; then
        get_mic_state
    fi
done
