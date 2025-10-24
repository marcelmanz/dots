#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
	echo "Usage: $0 <backup-directory>" >&2
	exit 1
fi

dest=$1
PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR:-"$HOME/.password-store"}

mkdir -p "$dest"

find "$PASSWORD_STORE_DIR" -type f -name '*.gpg' -print0 | while IFS= read -r -d '' item; do
	rel=$(realpath --relative-to "$PASSWORD_STORE_DIR" "$item")
	rel=${rel%.gpg}
	out="$dest/$rel"
	mkdir -p "$(dirname "$out")"
	pass show "$rel" > "$out"
	chmod 600 "$out"
done
