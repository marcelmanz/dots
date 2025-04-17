#!/usr/bin/env bash

DISPLAY_1=($(yabai -m query --spaces --display 1 | jq -r '.[] | select(."is-visible" == true) | .windows | @sh'))
DISPLAY_2=($(yabai -m query --spaces --display 2 | jq -r '.[] | select(."is-visible" == true) | .windows | @sh'))

for i in "${DISPLAY_1[@]}"; do
	yabai -m window "$i" --display 2
done

for i in "${DISPLAY_2[@]}"; do
	yabai -m window "$i" --display 1
done
