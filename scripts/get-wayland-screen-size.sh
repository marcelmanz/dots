#!/usr/bin/env bash

# Get wlr-randr output
output=$(wlr-randr)

# Extract physical dimensions in mm
width_mm=$(echo "$output" | grep -oP 'Physical size: \K\d+(?=x)')
height_mm=$(echo "$output" | grep -oP 'x\K\d+(?= mm)')

# Extract current resolution
resolution=$(echo "$output" | grep -oP '\d+x\d+ px(?=, \d+.\d+ Hz \(preferred, current\))')
width_px=$(echo $resolution | cut -d 'x' -f 1)
height_px=$(echo $resolution | cut -d 'x' -f 2)

# Check if the necessary information is found
if [ -z "$width_mm" ] || [ -z "$height_mm" ] || [ -z "$width_px" ] || [ -z "$height_px" ]; then
	echo "Unable to find screen information. Please ensure the output format of wlr-randr is correct."
	exit 1
fi

# Calculate the diagonal size in inches
diagonal_mm=$(echo "scale=2; sqrt($width_mm^2 + $height_mm^2)" | bc)
diagonal_inches=$(echo "scale=2; $diagonal_mm / 25.4" | bc)

# Display the screen size in inches
echo "Screen size: $diagonal_inches inches"
