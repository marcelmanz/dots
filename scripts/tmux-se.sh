#!/usr/bin/env bash

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <user> <hostname> [session_name]"
	echo "Example: $0 root 192.168.1.10"
	exit 1
fi

TARGET_USER=$1
TARGET_HOST=$2
SESSION_NAME=${3:-main}

if command -v mosh &>/dev/null; then
	mosh "${TARGET_USER}@${TARGET_HOST}" -- tmux new-session -A -s "${SESSION_NAME}"
else
	echo "fallback to ssh"
	ssh -t "${TARGET_USER}@${TARGET_HOST}" "tmux new-session -A -s ${SESSION_NAME}"
fi
