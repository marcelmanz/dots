#!/usr/bin/env bash
# Fix Bluetooth headset mic when the card is stuck on A2DP and the
# HSP/HFP profiles are missing or marked unavailable.
#
# Usage:
#   fix-micro.sh [MAC]
#
# MAC is optional; the first Bluetooth audio card is used if omitted.
# To go back to high quality playback: fix-audio.sh audio

set -euo pipefail

MAC="${1:-}"

mac_token() { echo "$1" | tr ':' '_'; }

find_card() {
  if [ -n "$MAC" ]; then
    pactl list short cards | awk -v m="bluez_card.$(mac_token "$MAC")" '$2 == m {print $2}' | head -n1
  else
    pactl list short cards | awk '/bluez_card/ {print $2; exit}'
  fi
}

headset_profile() {
  pactl list cards |
    sed -n "/Name: $1\$/,/Active Profile/p" |
    awk -F: '/^\t\theadset-head-unit.*available: yes/ {gsub(/^[ \t]+/, "", $1); print $1}' |
    sort | head -n1
}

CARD=$(find_card)
if [ -z "$CARD" ]; then
  echo "No Bluetooth audio device found. Pair/connect it first." >&2
  exit 1
fi
[ -n "$MAC" ] || MAC=$(echo "$CARD" | sed 's/^bluez_card\.//' | tr '_' ':')

echo "Device: $MAC | Card: $CARD"

PROFILE=$(headset_profile "$CARD")

if [ -z "$PROFILE" ]; then
  echo "No HSP/HFP profile offered — reconnecting device..."
  systemctl --user restart wireplumber 2>/dev/null || true
  bluetoothctl disconnect "$MAC" >/dev/null 2>&1 || true
  sleep 2
  bluetoothctl connect "$MAC" >/dev/null 2>&1 || true

  for _ in $(seq 10); do
    sleep 1
    CARD=$(find_card)
    [ -n "$CARD" ] || continue
    PROFILE=$(headset_profile "$CARD")
    [ -n "$PROFILE" ] && break
  done
fi

if [ -z "$PROFILE" ]; then
  echo "Still no HSP/HFP profile. Check that wireplumber has bluez5 HFP enabled" >&2
  echo "(bluez5.roles must include hfp_hf/hsp_hs) and that the headset is not" >&2
  echo "connected to another device." >&2
  exit 1
fi

pactl set-card-profile "$CARD" "$PROFILE"
echo "Profile: $PROFILE"

sleep 1
SRC=$(pactl list short sources | awk -v m="bluez_input.$(mac_token "$MAC")" 'index($2, m) == 1 {print $2; exit}')
if [ -z "$SRC" ]; then
  SRC=$(pactl list short sources | awk '/bluez/ {print $2; exit}')
fi

if [ -n "$SRC" ]; then
  pactl set-default-source "$SRC"
  echo "Default source (mic): $SRC"
else
  echo "Profile set but no Bluetooth mic source appeared." >&2
  exit 1
fi
