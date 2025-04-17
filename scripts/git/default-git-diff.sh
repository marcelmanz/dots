#!/usr/bin/env bash

ARGS=("$@")

# Find a better way of doing this
git config --global --unset diff.external
if [ -n "$ARGS" ]; then
	git diff "${ARGS[@]}"
else 
	git diff
fi
git config --global diff.external difft
