#!/usr/bin/env bash
set -euo pipefail

readarray -t IDS < <(
	hyprctl workspaces -j |
		jq -r '[.[] | select(.name|startswith("special:")|not) | {id, name}] |
         sort_by((.name|tonumber? // .id)) |
         .[].id'
)

((${#IDS[@]} == 0)) && exit 0

TMP="__TMP_WS_$$"
BATCH=""
i=1
for id in "${IDS[@]}"; do
	BATCH+="dispatch renameworkspace $id ${TMP}_$i;"
	((i++))
done
hyprctl --batch "$BATCH"

BATCH=""
i=1
for id in "${IDS[@]}"; do
	BATCH+="dispatch renameworkspace $id $i;"
	((i++))
done
hyprctl --batch "$BATCH"

notify-session "Reordered workspaces" \
	--icon "system-run" \
	--app-name "Hyprland" \
	--app-icon "hyprland" \
	--timeout 2000
