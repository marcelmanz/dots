#!/usr/bin/env bash

cache_file="/tmp/http-status-cache.csv"
max_age_days=$((180))

needs_refresh() {
	[[ ! -f "$cache_file" ]] && return 0
	age_days=$((($(date +%s) - $(stat -c %Y "$cache_file")) / 86400))
	((age_days > max_age_days))
}

if needs_refresh; then
	mkdir -p "$(dirname "$cache_file")"
	curl -s https://www.iana.org/assignments/http-status-codes/http-status-codes-1.csv >"$cache_file"
fi

data=$(cat "$cache_file")

lookup() {
	echo "$data" | awk -F, -v c="$1" '$1==c {print $1 " " $2}'
}

details() {
	curl -s "https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/$1" |
		htmlq ".content-section p" --text
}

if [[ -n "$1" && "$1" =~ ^[0-9]+$ ]]; then
	out=$(lookup "$1")
	if [[ -z "$out" ]]; then
		echo "No info available"
	else
		echo "$out"
		echo ""
		details "$1"
	fi
	exit
fi

selected=$(echo "$data" | tail -n +2 | awk -F, '{print $1 " " $2}' | fzf --prompt="HTTP Code > ")
[[ -z "$selected" ]] && exit

code=$(echo "$selected" | awk '{print $1}')

out=$(lookup "$code")
echo "$out"
echo ""
details "$code"
