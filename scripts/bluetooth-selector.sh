#!/usr/bin/env bash

notify_user() {
	local _status=$1
	local message=$2
	local icon=$3

	notify-send "$icon $message"
}

mapfile -t devices < <(bluetoothctl devices | grep "^Device")
mapfile -t connected_device_names < <(bluetoothctl devices Connected | cut --fields 3- --delimiter ' ')
mapfile -t all_device_names < <(printf '%s\n' "${devices[@]}" | cut --fields 3- --delimiter ' ')

connected_sign="✔️"
disconnected_sign="❌"

devices_result=""
for device in "${all_device_names[@]}"; do
	# Prepend a sign to each device name based on its connection status
	if [[ " ${connected_device_names[*]} " == *" $device "* ]]; then
		devices_result+="${connected_sign} $device"$'\n'
	else
		devices_result+="${disconnected_sign} $device"$'\n'
	fi
done

selected=$(printf "%s" "$devices_result" | tofi --prompt-text="Bluetooth devices: " | cut --fields=2- --delimiter=" ")

[[ -z $selected ]] && exit 1

device_id=$(printf '%s\n' "${devices[@]}" | awk -v dev="$selected" '$0 ~ dev {print $2}')

[[ -z "$device_id" ]] && exit 1

# Handle connections and notify the user
manage_connection() {
	local action=$1
	local device=$2
	local id=$3
	local sign=$4

	if bluetoothctl "$action" "$id"; then
		notify_user "$action" "$device" "$sign"
	else
		notify_user "$action" "Failed to $action $device" "❌"
	fi
}

# Toggle bluetooth connection
if printf "%s\n" "${connected_device_names[@]}" | grep -Fxq "$selected"; then
	notify_user "disconnect" "Disconnecting from $selected..." ">"
	manage_connection "disconnect" "$selected" "$device_id" "$disconnected_sign"
else
	notify_user "connect" "Connecting to $selected..." ">"
	manage_connection "connect" "$selected" "$device_id" "$connected_sign"
fi
