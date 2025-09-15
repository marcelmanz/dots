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

# Listen for pulseaudio events and output state on changes
# Only listen for relevant source events to reduce overhead
pactl subscribe | while read -r event; do
    if echo "$event" | grep -E "change.*source" >/dev/null; then
        get_mic_state
    fi
done
