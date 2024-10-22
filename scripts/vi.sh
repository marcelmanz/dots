#!/usr/bin/env bash

target="$*"

if [[ -e "$target" ]]; then
	nvim "$target"
else
	dir_path=$(dirname "$target")
	mkdir -p "$dir_path"
	nvim "$target"
fi
