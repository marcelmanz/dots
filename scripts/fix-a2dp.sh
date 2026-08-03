#!/usr/bin/env bash
# Fix missing audio on Bluetooth A2DP headsets
# Loads required PulseAudio modules, restarts PulseAudio, and forces A2DP profile.

set -euo pipefail

# Determine PulseAudio config path
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/pulse/default.pa"

# Ensure module-bluetooth-policy is loaded
if ! grep -q "load-module module-bluetooth-policy" "$CONFIG"; then
  echo "load-module module-bluetooth-policy" >> "$CONFIG"
  echo "Added module-bluetooth-policy to $CONFIG"
fi

# Ensure module-bluetooth-discover is loaded
if ! grep -q "load-module module-bluetooth-discover" "$CONFIG"; then
  echo "load-module module-bluetooth-discover" >> "$CONFIG"
  echo "Added module-bluetooth-discover to $CONFIG"
fi

# Restart PulseAudio for the current user
# In headless or container environments pulseaudio may not run as a systemd service.
if command -v systemctl >/dev/null 2>&1 && systemctl --user list-units | grep -q pulseaudio; then
  systemctl --user restart pulseaudio || true
else
  # Fallback: send TERM to any running pulseaudio instance
  if pgrep -x pulseaudio >/dev/null 2>&1; then
    pulseaudio -k || true
  fi
fi

echo "PulseAudio restarted (or killed if running)."

# Switch all Bluetooth cards to A2DP sink profile
BT_CARDS=$(pactl list short cards | grep -i bluez | cut -f1)
if [ -z "$BT_CARDS" ]; then
  echo "No Bluetooth audio cards detected – nothing to fix." >&2
else
  for CARD in $BT_CARDS; do
    if pactl set-card-profile "$CARD" a2dp_sink; then
      echo "Set card $CARD to a2dp_sink"
    else
      echo "Failed to set card $CARD to a2dp_sink" >&2
    fi
  done
fi

# Choose an A2DP sink as default if available
A2DP_SINK=$(pactl list short sinks | grep -i a2dp | head -n1 | cut -f1)
if [ -n "$A2DP_SINK" ]; then
  pactl set-default-sink "$A2DP_SINK"
  echo "Default sink set to $A2DP_SINK"
else
  echo "No A2DP sink found – ensure your headset is connected." >&2
fi

echo "A2DP audio configuration attempted. Verify output manually."
