#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ] || [ -z "${1:-}" ]; then
	echo "Usage ytrss <channel-link>"
	exit 1
fi

url="$1"

if [[ "$url" =~ /channel/(UC[[:alnum:]_-]+) ]]; then
	channel_id="${BASH_REMATCH[1]}"
else
	html=$(curl -fsL "$url")

	channel_id=$(printf '%s\n' "$html" |
		grep -oE 'https://www.youtube.com/channel/UC[[:alnum:]_-]+' |
		head -n1 |
		sed 's#.*/##')
fi

if [ -z "${channel_id:-}" ]; then
	echo "Could not find channel ID" >&2
	exit 1
fi

echo "https://www.youtube.com/feeds/videos.xml?channel_id=$channel_id"
