#!/usr/bin/env bash

# Control and report volume of the current default sink
# Uses pactl with @DEFAULT_SINK@ to always target the active output

case $1 in
  "up")     pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
  "down")   pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
  "toggle") pactl set-sink-mute   @DEFAULT_SINK@ toggle ;;
  *)         : ;;
esac

# Read current state
mute_line=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)
vol_line=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | head -n1)

if echo "$mute_line" | grep -q ": yes"; then
  volume="off"
  icon=""
else
  # Extract first percentage from the volume line
  vol_percent=$(echo "$vol_line" | grep -oE "[0-9]+%" | head -n1 | tr -d '%')
  vol_percent=${vol_percent:-0}
  if [ "$vol_percent" -gt 66 ]; then
    icon=""
  elif [ "$vol_percent" -gt 33 ]; then
    icon=""
  elif [ "$vol_percent" -gt 0 ]; then
    icon=""
  else
    icon=""
  fi
  volume="${vol_percent}%"
fi

echo "{\"content\": \"$volume\", \"icon\": \"$icon \"}"

