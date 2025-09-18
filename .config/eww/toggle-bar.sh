#!/usr/bin/env bash

# Toggle bars on all monitors: if any bar is open, close all; otherwise open on every monitor.

set -euo pipefail

any_open=false
if eww active-windows | grep -q '^bar'; then
  any_open=true
fi

if $any_open; then
  # Close all open bar windows that eww reports as active
  eww active-windows | awk '/^bar/ {print $1}' | while read -r w; do
    eww close "$w" 2>/dev/null || true
  done
  # Also try known bar IDs to be thorough
  for id in 0 1 2; do
    eww close "bar${id}" 2>/dev/null || true
  done
else
  # Open on all detected monitors
  monitors=$(hyprctl monitors -j | jq -r '.[].id')
  for monitor in ${monitors}; do
    eww open "bar${monitor}"
  done
fi
