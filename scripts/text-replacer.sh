#!/usr/bin/env bash

file_path=$1
declare -A placeholders # Declare an associative array to store user inputs
result=""

while IFS= read -r line; do
	while [[ $line =~ \[([^\]]+)\] ]]; do
		placeholder="${BASH_REMATCH[1]}"

		# Check if the placeholder has already been given a value
		if [[ -z "${placeholders[$placeholder]}" ]]; then
			echo -n "Enter value for '$placeholder': "
			read -r replacement </dev/tty
			placeholders[$placeholder]=$replacement
		else
			replacement="${placeholders[$placeholder]}"
		fi

		line="${line//\[$placeholder\]/$replacement}"
	done
	result+="$line"$'\n'
done <"$file_path"

echo "$result" | wl-copy
