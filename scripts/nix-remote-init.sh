#!/usr/bin/env bash

REPO="$HOME/clones/own/dev-templates"
LANG="${1:-}"

if [ -z "${LANG}" ]; then
	if command -v fzf >/dev/null 2>&1; then
		CHOICES="$(find "$REPO" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | grep -v '^\.' | sort -u)"
		LANG="$(printf "%s\n" "$CHOICES" | fzf --prompt="language> ")"
		[ -z "$LANG" ] && {
			echo "no language selected"
			exit 2
		}
	else
		echo "usage: $0 <language>"
		exit 2
	fi
fi

if [ ! -d .git ]; then
	echo "Not a git repository"
	exit 1
fi

EXCLUDE_FILE=".git/info/exclude"

mkdir -p .git/info
touch "$EXCLUDE_FILE"

{
	echo "# Custom excludes"
	echo ".direnv/"
	echo ".envrc"
} >>"$EXCLUDE_FILE"

echo "updated $EXCLUDE_FILE"

TEMPLATE_PATH="$(ls -1d "$REPO"/"$LANG"/ 2>/dev/null | head -n1)"
[ -z "$TEMPLATE_PATH" ] && {
	echo "template not found for $LANG"
	exit 3
}
printf 'use flake "%s"\n' "$TEMPLATE_PATH" >.envrc

direnv allow
