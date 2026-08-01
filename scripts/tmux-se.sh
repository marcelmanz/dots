#!/usr/bin/env bash

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <user> <hostname> [session_name]"
	echo "Example: $0 root 192.168.1.10"
	exit 1
fi

TARGET_USER=$1
TARGET_HOST=$2
DEFAULT_SESSION=${3:-main}

SESSIONS=$(ssh -q "${TARGET_USER}@${TARGET_HOST}" "tmux ls -F '#S' 2>/dev/null")

if [ -n "$SESSIONS" ]; then
	if command -v fzf &>/dev/null; then
		SELECTED=$(printf "%s\n[Create New Session]" "$SESSIONS" | fzf --prompt="Select session on ${TARGET_HOST}: ")

		if [ -z "$SELECTED" ]; then
			echo "No session selected. Aborting."
			exit 0
		fi

		if [ "$SELECTED" = "[Create New Session]" ]; then
			SESSION_NAME=$DEFAULT_SESSION
		else
			SESSION_NAME=$SELECTED
		fi
	else
		echo "fzf not found. Defaulting to session: ${DEFAULT_SESSION}"
		SESSION_NAME=$DEFAULT_SESSION
	fi
else
	SESSION_NAME=$DEFAULT_SESSION
fi

if [[ "${TARGET_HOST}" == "mlab-local" ]] && command -v mosh &>/dev/null; then
	mosh "${TARGET_USER}@${TARGET_HOST}" -- tmux new-session -A -s "${SESSION_NAME}"
else
	echo "fallback to ssh"
	ssh -t "${TARGET_USER}@${TARGET_HOST}" "tmux new-session -A -s ${SESSION_NAME}"
fi
