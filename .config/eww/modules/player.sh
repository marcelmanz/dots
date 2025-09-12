#!/bin/sh

echo "{\"show\": \"no\", \"content\": \"\"}"

check_player() {
    status="$(playerctl status 2>/dev/null || echo "Stopped")"
    
    # Only show if actively playing
    if [ "$status" = "Playing" ]; then
        artist="$(playerctl metadata artist 2>/dev/null || echo "")"
        title="$(playerctl metadata title 2>/dev/null || echo "")"
        
        if [ -n "$artist" ] && [ -n "$title" ]; then
            text="$artist - $title"
            echo "{\"show\": \"yes\", \"content\": \"(box (label :text \\\"$text\\\"))\"}"
            return 0  # Playing
        fi
    fi
    
    echo "{\"show\": \"no\", \"content\": \"\"}"
    return 1  # Not playing
}

# Adaptive polling: 1s when playing, 5s when idle
while true; do
    if check_player; then
        sleep 1  # Check every second when playing
    else
        sleep 5  # Check every 5 seconds when idle
    fi
done 

