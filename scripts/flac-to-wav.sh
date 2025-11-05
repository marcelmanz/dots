#!/usr/bin/env bash
set -e

SRC_DIR=$(realpath .)
DST_DIR="$SRC_DIR/wav"
mkdir -p "$DST_DIR"

cd "$SRC_DIR"
find . -type f -iname "*.flac" -print0 | while IFS= read -r -d '' rel; do
	rel="${rel#./}"
	in="$SRC_DIR/$rel"
	out="$DST_DIR/${rel%.*}.wav"
	mkdir -p "$(dirname "$out")"
	echo "Converting: $rel -> wav/${rel%.*}.wav"
	ffmpeg -loglevel error -y -i "$in" -acodec pcm_s16le -ar 44100 "$out"
done

echo "✅ Conversion complete. WAV files are in: $DST_DIR"
