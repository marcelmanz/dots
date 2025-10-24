#!/usr/bin/env bash
set -euo pipefail

cfg="${HOME}/.config/kanshi/config"
backup="$(mktemp)"
tmp="$(mktemp)"
img="$(mktemp --suffix=.png)"

cp "$cfg" "$backup"

restore() {
  killall kanshi || true
  cp "$backup" "$cfg" || true
  kanshi &>/dev/null &
}
trap restore EXIT

perl -pe 's/(\bscale\s+)[0-9.]+/$1 1/g' "$backup" >"$tmp"

killall kanshi || true
kanshi -c "$tmp" &

sleep 1

geom="$(slurp)"
grim -s 1 -g "$geom" "$img"

restore

swappy -f "$img"

trap - EXIT
restore
rm -f "$tmp" "$backup" "$img"
