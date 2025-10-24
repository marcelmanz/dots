#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
	echo "Usage: $0 <backup-directory>" >&2
	exit 1
fi

src=$1

if [ ! -d "$src" ]; then
	echo "Directory not found: $src" >&2
	exit 1
fi

src=$(realpath "$src")

find "$src" -type f -print0 | while IFS= read -r -d '' file; do
	rel=$(realpath --relative-to "$src" "$file")
	pass insert -m -f "$rel" < "$file"
done
