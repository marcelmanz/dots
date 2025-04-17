#!/usr/bin/env bash

CONFIG_FILES="$HOME/.config/waybar/config $HOME/.config/waybar/style.css"

trap "killall waybar" EXIT

while true; do
    waybar &
    killall waybar
done
