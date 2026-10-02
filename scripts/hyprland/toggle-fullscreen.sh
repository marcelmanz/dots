#!/usr/bin/env bash

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

if ! command_exists hyprctl; then
	echo "Error: 'hyprctl' command not found."
	exit 1
fi

current_workspace=$(hyprctl activeworkspace -j | jq -r '.id')
hyprland_clients=$(hyprctl clients -j)

echo "$hyprland_clients" | jq -c '.[]' | while read -r obj; do
	fullscreen=$(echo "$obj" | jq -r '.fullscreen')
	workspace_id=$(echo "$obj" | jq -r '.workspace.id')

	if [ "$workspace_id" = "$current_workspace" ] && [ "$fullscreen" -gt 0 ]; then
		if [ "$fullscreen" -eq 2 ]; then
			hyprctl dispatch 'hl.dsp.window.fullscreen({mode="fullscreen",action="unset"})'
		else
			hyprctl dispatch 'hl.dsp.window.fullscreen({action="unset"})'
		fi
	fi
done

# Execute the command if provided
if [ $# -gt 0 ]; then
	eval "$@"
fi
