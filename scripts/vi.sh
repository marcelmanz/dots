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

#  path:line:col: open file at given line and column
if [[ "$args" =~ ^(.+):([0-9]+):([0-9]+)$ ]]; then
	file="${BASH_REMATCH[1]}"
	line="${BASH_REMATCH[2]}"
	col="${BASH_REMATCH[3]}"
	[[ -e "$file" ]] || {
		dir_path=$(dirname "$file")
		mkdir -p "$dir_path"
	}
	nvim +"call cursor(${line},${col})" "$file"
	if [[ ! -s "$file" ]]; then
		rm "$file"
	fi
	if [[ -d "$dir_path" && -z "$(ls -A "$dir_path")" ]]; then
		rmdir "$dir_path"
	fi
	exit $?
	# path:line: open file at given line
elif [[ "$args" =~ ^(.+):([0-9]+)$ ]]; then
	file="${BASH_REMATCH[1]}"
	line="${BASH_REMATCH[2]}"
	[[ -e "$file" ]] || {
		dir_path=$(dirname "$file")
		mkdir -p "$dir_path"
	}
	nvim +"$line" "$file"
	if [[ ! -s "$file" ]]; then
		rm "$file"
	fi
	if [[ -d "$dir_path" && -z "$(ls -A "$dir_path")" ]]; then
		rmdir "$dir_path"
	fi
	exit $?
fi

# Existing file -> open it;
# otherwise create dirs & open new file
if [[ -e "$args" ]]; then
	# for files
	nvim "$args"
else
	# for directories
	dir_path=$(dirname "$args")
	mkdir -p "$dir_path"
	nvim "$args"
	if [[ -d "$dir_path" && -z "$(ls -A "$dir_path")" ]]; then
		rmdir "$dir_path"
	fi
fi
