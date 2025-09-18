#!/usr/bin/env bash

# Get current monitor ID from active window
current_monitor=$(hyprctl activewindow -j | jq -r '.monitor // 0')

# Check if bar is already open on current monitor
if eww active-windows | grep -q "bar${current_monitor}"; then
    # Bar is on current monitor - just close it
    eww close "bar${current_monitor}"
else
    # Bar is either not open or on different monitor
    # Close all bars first
    eww close bar0 2>/dev/null
    eww close bar1 2>/dev/null  
    eww close bar2 2>/dev/null
    
    # Open bar on current monitor
    eww open "bar${current_monitor}"
fi