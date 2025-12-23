#!/usr/bin/env bash

set -euo pipefail

NOTES_DIR="$HOME/notes"

if [ $# -eq 0 ]; then
    echo "Usage: note [zk options] -- <title>"
    exit 1
fi

ZK_ARGS=()
TITLE=()

while [ $# -gt 0 ]; do
    case "$1" in
        --)
            shift
            TITLE=("$@")
            break
            ;;
        *)
            ZK_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ ${#TITLE[@]} -eq 0 ]; then
    echo "Error: missing title"
    exit 1
fi

cd "$NOTES_DIR" || exit 1

NOTE_PATH=$(zk new "${ZK_ARGS[@]}" --title "${TITLE[*]}" --print-path)

if [ -n "$NOTE_PATH" ]; then
    echo "Created note: $NOTE_PATH"
    nvim "$NOTE_PATH"
else
    echo "Error: Failed to create note"
    exit 1
fi

cd - >/dev/null 2>&1

