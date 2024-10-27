#!/usr/bin/env bash

args="$*"

# no arguments
if [[ -z "$args" ]]; then
	nvim
	error_code=$?
	exit $error_code
fi

# for flags
if [[ "$args" == -* ]]; then
	nvim "$args"
	error_code=$?
	exit $error_code
fi

if [[ -e "$args" ]]; then
	# for files
	nvim "$args"
else
	# for directories
	dir_path=$(dirname "$args")
	mkdir -p "$dir_path"
	nvim "$args"
fi
