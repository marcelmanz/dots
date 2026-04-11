#!/usr/bin/env bash

URL=$(cat | curl -s --data-binary @- https://paste.rs)

URL=$(echo "$URL" | tr -d '\n\r')

if [ -z "$URL" ] || [[ "$URL" != *"paste.rs"* ]]; then
	tmux display-message "Paste upload failed!"
	exit 1
fi

tmux display-message -d 0 "Uploaded to: $URL  (Press any key to clear)"
