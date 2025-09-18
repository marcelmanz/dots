#!/usr/bin/env bash

# Get monitor IDs
monitors=$(hyprctl monitors -j | jq -r '.[] | .id')

# Generate window definitions for each monitor
for monitor in ${monitors}; do
    cat << EOF
(defwindow bar${monitor}
  :monitor ${monitor}
  :exclusive true
  :focusable false
  :geometry (geometry :anchor "top center" :x "0%" :y "0" :width "100%" :height "20px")
  (bar :screen ${monitor}))

EOF
done