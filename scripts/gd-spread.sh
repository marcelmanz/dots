#!/usr/bin/env bash


if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Not a git repository – skipping diff."
  exit 0
fi

args=("$@")
arg="$1"

if [[ $arg == *".."* ]]; then
	start_head=$(echo "$args" | awk -F'\.\.' '{print $1}')
	last_head=$(echo "$args" | awk -F'\.\.' '{print $2}')
	git diff "HEAD~$start_head" "HEAD~$last_head"
	exit 1
fi

if [[ $arg == "HEAD~"* ]]; then
	git diff $args
	exit 1
fi

if [[ $arg =~ ^[0-9]+$ ]]; then
	git diff "HEAD~$args"
	exit 1
fi

git diff $args

