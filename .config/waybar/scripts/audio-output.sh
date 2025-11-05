#!/usr/bin/env bash
current=$(pactl info | grep "Default Sink" | awk -F': ' '{print $2}')
icon=""

printf '{"text":"%s %s","tooltip":"Current output: %s"}\n' "$icon" "$current" "$current"
