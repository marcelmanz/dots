#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/how"
STATE_FILE="$STATE_DIR/session"
mkdir -p "$STATE_DIR"

continue=false
if [[ "${1:-}" == "--continue" ]]; then
	continue=true
	shift
fi

q="$*"
if [[ -z "$q" ]]; then
	q="$(cat)"
fi

out="$(mktemp)"
err="$(mktemp)"

if $continue && [[ -f "$STATE_FILE" ]]; then
	sid="$(cat "$STATE_FILE")"
	cmd=(claude -p --output-format json --resume "$sid")
else
	cmd=(claude -p --output-format json)
fi

prompt=$'Answer concisely in Markdown.\n\n'"$q"

"${cmd[@]}" "$prompt" >"$out" 2>"$err" &
pid=$!

if [[ -t 1 ]]; then
	tput civis
	trap 'tput cnorm; kill "$pid" 2>/dev/null || true; printf "\n"; exit' INT TERM EXIT

	frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
	i=0
	while kill -0 "$pid" 2>/dev/null; do
		printf "\r%s thinking…" "${frames[i]}"
		i=$(((i + 1) % ${#frames[@]}))
		sleep 0.08
	done

	set +e
	wait "$pid"
	status=$?
	set -e

	printf "\r\033[K"
	tput cnorm
	trap - INT TERM EXIT
else
	set +e
	wait "$pid"
	status=$?
	set -e
fi

if [[ -s "$err" ]]; then
	cat "$err" >&2
fi

if jq -e . >/dev/null 2>&1 <"$out"; then
	sid="$(jq -r '.[] | select(.type == "result") | .session_id // empty' <"$out")"
	result="$(jq -r '.[] | select(.type == "result") | .result // empty' <"$out")"
	is_error="$(jq -r '.[] | select(.type == "result") | .is_error // false' <"$out")"

	if [[ -n "$sid" ]]; then
		printf '%s\n' "$sid" >"$STATE_FILE"
	fi

	if [[ "$is_error" == "true" || -z "$result" ]]; then
		cat "$out"
		rm -f "$out" "$err"
		exit "${status:-1}"
	fi

	if command -v bat >/dev/null && [[ -t 1 ]]; then
		bat --language markdown --paging never --style plain <<<"$result"
	else
		printf '%s\n' "$result"
	fi
else
	cat "$out"
fi

rm -f "$out" "$err"
