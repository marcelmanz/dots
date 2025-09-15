#!/usr/bin/env bash

# Function to get current speaker state
get_speaker_state() {
    mute=$(pamixer --get-mute)
    if [ "$mute" = "true" ]; then
        volume="off"
        icon=""
    else 
        volume="$(pamixer --get-volume)"
        if [ "$volume" -gt 66 ]; then
            icon=""
        elif [ "$volume" -gt 33 ]; then
            icon=""
        elif [ "$volume" -gt 0 ]; then 
            icon=""
        else 
            icon=""
        fi
        volume="$volume%"
    fi
    echo "{\"content\": \"$volume\", \"icon\": \"$icon \"}"
}

# Output initial state
get_speaker_state

# Listen for pulseaudio events and output state on changes
# Only listen for relevant sink events to reduce overhead
pactl subscribe | while read -r event; do
    if echo "$event" | grep -E "change.*sink" >/dev/null; then
        get_speaker_state
    fi
done
