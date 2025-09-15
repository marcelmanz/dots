#!/usr/bin/env bash

# pkill -f "eww open" 2>/dev/null
# pkill -f "eww daemon" 2>/dev/null
# eww kill 2>/dev/null
# eww open bar0 &
# eww open bar1 &

# Close if already open
eww close bar0
eww close bar1

# Reopen immediately (no daemon restart → instant)
eww open bar0
eww open bar1
