#!/usr/bin/env bash

module_name="keyboard-layout"
socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

print_layout() {
	read -r index code < <(hyprctl devices -j | jq -r '[.keyboards[] | select(.layout | contains(","))][0] | .active_layout_index as $i | "\($i) \(.layout | split(",")[$i] | ascii_upcase)"')

	if [ "$index" = 0 ]; then
		ironbar style remove-class "$module_name" non-default >/dev/null 2>&1
	else
		ironbar style add-class "$module_name" non-default >/dev/null 2>&1
	fi

	echo "$code"
}

print_layout

socat -U - "UNIX-CONNECT:$socket" | while read -r event; do
	[[ $event == activelayout\>\>* ]] && print_layout
done
