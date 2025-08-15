#!/usr/bin/env bash
set -e

branch="${@: -1}"
if git checkout "$@"; then
	echo "Checked out to '$branch'."
else
	echo "Branch not found locally. Fetching from origin..."
	if git fetch origin "$branch:$branch"; then
		echo "Fetched branch. Checking out..."
		git checkout "$branch"
	else
		echo "Failed to fetch branch '$branch' from origin." >&2
		exit 1
	fi
fi
