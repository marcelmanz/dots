#!/usr/bin/env bash

set -e

NAME="$1"
KEY_PATH="$HOME/.ssh/id_ed25519_$NAME"

if [ -z "$NAME" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi

if ! [[ "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid name. Use only letters, numbers, underscores, and hyphens."
    exit 1
fi

if [ -f "$KEY_PATH" ]; then
    echo "Key already exists: $KEY_PATH"
    exit 1
fi

ssh-keygen -t ed25519 -a 100 -f "$KEY_PATH" -C "$NAME" -N "" </dev/null

ssh-add "$KEY_PATH"

cat "$KEY_PATH.pub"
