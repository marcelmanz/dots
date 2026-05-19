#!/usr/bin/env bash

TMP_IMG="/tmp/ocr_temp.png"

hyprshot -m region -s -o /tmp -f ocr_temp.png

if [ -f "$TMP_IMG" ]; then
	# 2. Extract text and pipe to clipboard
	tesseract "$TMP_IMG" stdout | wl-copy

	# 3. Send a desktop notification with the extracted text
	notify-send "OCR Extracted" "$(wl-paste)"

	# 4. Clean up the temp file
	rm "$TMP_IMG"
fi
