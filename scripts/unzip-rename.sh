#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ]; then
	echo "Usage: $(basename "$0") <file.zip | 'glob' | regex>..."
	echo "Extracts each zip into the current directory as <zipname>_<file>."
	exit 1
fi

zips=()
for arg in "$@"; do
	if [ -f "$arg" ]; then
		zips+=("$arg")
	elif matches=$(compgen -G "$arg"); then
		while IFS= read -r match; do zips+=("$match"); done <<<"$matches"
	else
		while IFS= read -r -d '' match; do
			zips+=("$match")
		done < <(find . -maxdepth 1 -type f -regextype posix-extended -regex "\./$arg" -print0)
	fi
done

if [ ${#zips[@]} -eq 0 ]; then
	echo "No files match: $*"
	exit 1
fi

for zip in "${zips[@]}"; do
	name="$(basename "${zip%.*}")"
	tmp="$(mktemp -d)"
	unzip -q "$zip" -d "$tmp"
	find "$tmp" -type f -print0 | while IFS= read -r -d '' file; do
		target="./${name}_$(basename "$file")"
		if [ -e "$target" ]; then
			echo "Skipping, already exists: $target"
		else
			mv "$file" "$target"
			echo "$target"
		fi
	done
	rm -rf "$tmp"
done
