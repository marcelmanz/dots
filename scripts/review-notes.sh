#!/usr/bin/env bash

set -euo pipefail

NOTES_DIR="${1:-/home/$USER/clones/own/notes}"

is_minimal() {
    local file="$1"
    local lines

    lines=$(grep -v '^[[:space:]]*$' "$file" | wc -l)

    [[ $lines -eq 0 ]] && return 0
    [[ $lines -eq 1 ]] && grep -q '^#' "$file" && return 0
    [[ $lines -eq 2 ]] && grep -q '^#' "$file" && grep -q '^[[:space:]]*-[[:space:]]\[' "$file" && return 0

    return 1
}

while IFS= read -r -d '' file; do
    if is_minimal "$file"; then
        echo "File: $file"
        cat "$file"
        echo
        read -r -p "Delete? [y/n/q] " answer </dev/tty
        case $answer in
        [Yy]*)
            rm "$file"
            echo "Deleted"
            ;;
        [Qq]*) exit 0 ;;
        *) echo "Kept" ;;
        esac
        echo
    fi
done < <(find "$NOTES_DIR" -type f -name "*.md" -print0)

echo "Done!"
echo
git -C "$NOTES_DIR" status
