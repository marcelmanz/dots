#!/usr/bin/env bash
set -euo pipefail

# Usage: render.sh diagram.mmd diagram.svg
# Also writes diagram.png, because imv re-renders SVGs on the CPU every frame
# and hangs when zoomed in.
# Follows the system light/dark preference and bakes in a background rect,
# because some viewers ignore the CSS background merman-cli writes.

input="$1"
output="$2"

scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)"
if [[ "$scheme" == *dark* ]]; then
	theme=dark
	background='#1e1e1e'
else
	theme=default
	background='#ffffff'
fi

merman-cli render "$input" --svg-pipeline resvg-safe -t "$theme" -b "$background" -o "$output"

python3 - "$output" "$background" <<'PY'
import re
import sys

path, background = sys.argv[1], sys.argv[2]
svg = open(path).read()
tag = re.search(r"<svg[^>]*>", svg)
x, y, width, height = re.search(r'viewBox="([^"]+)"', tag.group(0)).group(1).split()
rect = f'<rect x="{x}" y="{y}" width="{width}" height="{height}" fill="{background}"/>'
open(path, "w").write(svg[: tag.end()] + rect + svg[tag.end() :])
PY

sans_serif="$(fc-match -f '%{family}' sans-serif)"
nix shell nixpkgs#resvg -c resvg --quiet --zoom 3 --sans-serif-family "$sans_serif" \
    "$output" "${output%.svg}.png"
