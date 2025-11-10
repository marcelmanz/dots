#!/usr/bin/env bash

default_webcam=$(ls /dev/video* | head -n 1)

if [ -z "$1" ]; then
	webcam_number=$default_webcam
else
	webcam_number="/dev/video$1"
fi

if [ ! -e "$webcam_number" ]; then
	echo "Error: Webcam device $webcam_number not found."
	exit 1
fi

gst-launch-1.0 -v v4l2src device="$webcam_number" ! videoconvert ! videoflip method=horizontal-flip ! autovideosink
