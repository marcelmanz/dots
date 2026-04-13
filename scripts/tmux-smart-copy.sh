#!/usr/bin/env bash

INPUT=$(cat)
CLIENT_PID=$(tmux display-message -p '#{client_pid}')
CONNECTION_TYPE="local"
PID=$CLIENT_PID

while [ -n "$PID" ] && [ "$PID" -gt 1 ]; do
	COMM=$(ps -o comm= -p "$PID" | tr -d ' ')
	if [[ "$COMM" == "mosh-server" ]]; then
		CONNECTION_TYPE="mosh"
		break
	elif [[ "$COMM" == "sshd" ]]; then
		CONNECTION_TYPE="ssh"
		break
	fi
	PID=$(ps -o ppid= -p "$PID" | tail -n1 | tr -d ' ')
done

case "$CONNECTION_TYPE" in
"mosh")
	URL=$(echo "$INPUT" | curl -s --data-binary @- https://paste.rs | tr -d '\n\r')
	if [ -n "$URL" ] && [[ "$URL" == *"paste.rs"* ]]; then
		tmux display-message -d 0 "Mosh Detected: Uploaded to $URL (Press any key)"
	else
		tmux display-message "Mosh failed to upload to paste.rs!"
	fi
	;;
"local")
	if command -v wl-copy >/dev/null 2>&1; then
		echo "$INPUT" | wl-copy
	fi
	;;
esac
