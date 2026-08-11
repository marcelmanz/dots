#!/usr/bin/env bash
# Fix Bluetooth audio/mic on PipeWire (legacy PulseAudio fallback).
#
# Symptoms this targets:
#   - Device connected, shows a2dp_sink, but silent (transport not acquired).
#   - No microphone (stuck on A2DP, which has no mic source).
#
# Usage:
#   fix-audio.sh                # default: fix silent audio (reconnect + A2DP)
#   fix-audio.sh audio [MAC]    # force A2DP profile + default sink (best quality, no mic)
#   fix-audio.sh mic   [MAC]    # force HSP/HFP profile + default source (enables mic)
#
# MAC is optional; first Bluetooth audio card is used if omitted.

set -euo pipefail

MODE="${1:-audio}"
MAC="${2:-}"

if pgrep -x pipewire >/dev/null 2>&1; then
  SERVER="pipewire"
elif pgrep -x pulseaudio >/dev/null 2>&1; then
  SERVER="pulseaudio"
else
  echo "No PipeWire or PulseAudio running." >&2
  exit 1
fi

mac_token() { echo "$1" | tr ':' '_'; }

if [ -n "$MAC" ]; then
  CARD=$(pactl list short cards | grep -i "bluez_card.$(mac_token "$MAC")" | awk '{print $2}' | head -n1)
else
  CARD=$(pactl list short cards | grep bluez_card | head -n1 | awk '{print $2}')
  MAC=$(echo "$CARD" | sed 's/^bluez_card\.//' | tr '_' ':')
fi

if [ -z "$CARD" ] || [ -z "$MAC" ]; then
  echo "No Bluetooth audio device found. Pair/connect it first." >&2
  exit 1
fi

echo "Server: $SERVER | Device: $MAC | Card: $CARD"

restart_transport() {
  if [ "$SERVER" = "pipewire" ]; then
    systemctl --user restart wireplumber 2>/dev/null || true
  else
    systemctl --user restart pulseaudio 2>/dev/null || pulseaudio -k 2>/dev/null || true
  fi
  sleep 1
  bluetoothctl disconnect "$MAC" 2>/dev/null || true
  sleep 1
  bluetoothctl connect "$MAC" 2>/dev/null || true
  sleep 1
  CARD=$(pactl list short cards | grep -i "bluez_card.$(mac_token "$MAC")" | awk '{print $2}' | head -n1)
}

set_a2dp() {
  pactl set-card-profile "$CARD" a2dp-sink 2>/dev/null ||
    pactl set-card-profile "$CARD" a2dp-sink-sbc_xq 2>/dev/null || true
  local sink
  sink=$(pactl list short sinks | grep -i "bluez_output.$(mac_token "$MAC")" | awk '{print $2}' | head -n1)
  if [ -n "$sink" ]; then
    pactl set-default-sink "$sink"
    echo "Default sink: $sink"
  else
    echo "No A2DP sink appeared — reconnect failed?" >&2
  fi
}

set_hfp() {
  pactl set-card-profile "$CARD" headset-head-unit 2>/dev/null ||
    pactl set-card-profile "$CARD" headset-head-unit-cvsd 2>/dev/null || true
  sleep 1
  local src
  src=$(pactl list short sources | grep -i "bluez_input.$(mac_token "$MAC")" | awk '{print $2}' | head -n1)
  if [ -n "$src" ]; then
    pactl set-default-source "$src"
    echo "Default source (mic): $src"
  else
    echo "No BT mic source found — device may not offer HFP." >&2
  fi
}

case "$MODE" in
audio)
  echo "Mode: fix audio (A2DP)"
  restart_transport
  set_a2dp
  ;;
mic)
  echo "Mode: enable mic (HSP/HFP)"
  set_hfp
  ;;
*)
  echo "Usage: $0 [audio|mic] [MAC]" >&2
  exit 1
  ;;
esac

echo "Done. Verify with: pactl list cards | grep -A2 'Active Profile'"
