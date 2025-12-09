#!/usr/bin/env bash

get_webcam_info() {
	local device=$1
	local name=$(v4l2-ctl --device="$device" --info 2>/dev/null | grep "Card type" | cut -d: -f2 | xargs)
	if [ -z "$name" ]; then
		name="Unknown Device"
	fi
	echo "$device - $name"
}

is_primary_capture_device() {
	local device=$1
	v4l2-ctl --device="$device" --all 2>/dev/null | grep -A2 "Device Caps" | grep -q "Video Capture"
}

if [ -n "$1" ]; then
	webcam_number="/dev/video$1"
else
	mapfile -t all_devices < <(ls /dev/video* 2>/dev/null)
	
	devices=()
	for device in "${all_devices[@]}"; do
		if is_primary_capture_device "$device"; then
			devices+=("$device")
		fi
	done
	
	if [ ${#devices[@]} -eq 0 ]; then
		echo "Error: No webcam devices found."
		exit 1
	fi
	
	if [ ${#devices[@]} -eq 1 ]; then
		webcam_number="${devices[0]}"
	else
		webcam_list=""
		for device in "${devices[@]}"; do
			webcam_list+="$(get_webcam_info "$device")"$'\n'
		done
		
		selected=$(echo -n "$webcam_list" | tofi --prompt-text "Select webcam: ")
		
		if [ -z "$selected" ]; then
			echo "No webcam selected."
			exit 0
		fi
		
		webcam_number=$(echo "$selected" | cut -d' ' -f1)
	fi
fi

if [ ! -e "$webcam_number" ]; then
	echo "Error: Webcam device $webcam_number not found."
	exit 1
fi

gst-launch-1.0 -v v4l2src device="$webcam_number" ! videoconvert ! videoflip method=horizontal-flip ! autovideosink
