#!/usr/bin/env bash

# output        take screenshot of an entire monitor
# window        take screenshot of an open window
# region        take screenshot of selected region
# active        take screenshot of active window|output
#               (you must use --mode again with the intended selection)
# OUTPUT_NAME   take screenshot of output with OUTPUT_NAME
#               (you must use --mode again with the intended selection)
#               (you can get this from `hyprctl monitors`)

# bind = $mainMod SHIFT, PRINT, exec, hyprshot -m region

# hyprshot -m region

# get last file from /screenshots
# last_screenshot=$(find ~/screenshots -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")

grim -g "$(slurp)" ~/screenshots/grim-"$(date '+%Y%m%d-%H:%M:%S')".png
