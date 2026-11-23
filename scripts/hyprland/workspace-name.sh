#!/usr/bin/env bash

socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

print_name() {
	hyprctl -j activeworkspace | jq -r '.name'
}

print_name

socat -U - "UNIX-CONNECT:$socket" | while read -r event; do
	case $event in
	workspacev2\>\>* | focusedmonv2\>\>* | renameworkspace\>\>*) print_name ;;
	esac
done
