#!/usr/bin/env bash

output=$(hyprshot --mode region --raw | zbarimg --raw - 2>&1)

if [[ $? -ne 0 ]]; then
	notify-send "Error" "QR scanned failed"
	exit 1
fi

number_of_scans=$(echo "$output" | grep -oP 'scanned \K\d+')
scanned_content=$(echo "$output" | awk '/scanned [0-9]+ barcode symbols from [0-9]+ images in [0-9.]+ seconds/{exit} {print}')

if [[ $number_of_scans -ge 2 ]]; then
	selected=$(echo "$scanned_content" | ~/.nix-profile/bin/tofi)
	echo "$selected" | wl-copy
	notify-send "Copied to clipboard" "$selected"
else
	echo "$scanned_content" | wl-copy
	notify-send "Copied to clipboard" "$scanned_content"
fi
