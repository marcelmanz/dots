#!/usr/bin/env bash

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
	echo "Not a git repository – skipping diff."
	exit 0
fi

flags=()
positional=()

for arg in "$@"; do
	if [[ $arg == -* ]]; then
		flags+=("$arg")
	else
		positional+=("$arg")
	fi
done

first_pos="${positional[0]}"

# Handle range syntax ("5..2")
if [[ $first_pos == *".."* ]]; then
	start_head="${first_pos%%..*}"
	last_head="${first_pos#*..}"

	# only prefix with HEAD~ if both are pure numbers
	if [[ $start_head =~ ^[0-9]+$ ]]; then
		start_head="HEAD~$start_head"
	fi
	if [[ $last_head =~ ^[0-9]+$ ]]; then
		last_head="HEAD~$last_head"
	fi

	git diff "${flags[@]}" "$start_head" "$last_head" "${positional[@]:1}"
	exit 0
fi

# Handle HEAD~ syntax ("HEAD~5")
if [[ $first_pos == "HEAD~"* ]]; then
	git diff "${flags[@]}" "${positional[@]}"
	exit 0
fi

# Handle numeric syntax ("5")
if [[ $first_pos =~ ^[0-9]+$ ]]; then
	git diff "${flags[@]}" "HEAD~$first_pos" "${positional[@]:1}"
	exit 0
fi

# Default: pass everything through
git diff "${flags[@]}" "${positional[@]}"
