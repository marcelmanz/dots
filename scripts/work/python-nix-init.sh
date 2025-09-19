#!/usr/bin/env bash

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
	echo ".ropeproject/"
	echo ".venv/"
} >>"$EXCLUDE_FILE"

echo "updated $EXCLUDE_FILE"

touch .envrc
echo 'use flake "/home/mmanzanares/clones/own/dev-templates/python"' >.envrc

direnv allow
