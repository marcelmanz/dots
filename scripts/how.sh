#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/how"
STATE_FILE="$STATE_DIR/session"
mkdir -p "$STATE_DIR"

continue=false
pager=""
while [[ $# -gt 0 ]]; do
	case "${1:-}" in
	--continue | -c)
		continue=true
		shift
		;;
	--pager)
		pager="$2"
		shift 2
		;;
	*)
		break
		;;
	esac
done

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
	sid="$(jq -r 'if type == "array" then .[] | select(.type == "result") | .session_id // empty else select(.type == "result") | .session_id // empty end' <"$out")"
	result="$(jq -r 'if type == "array" then .[] | select(.type == "result") | .result // empty else select(.type == "result") | .result // empty end' <"$out")"
	is_error="$(jq -r 'if type == "array" then .[] | select(.type == "result") | .is_error // false else select(.type == "result") | .is_error // false end' <"$out")"

	if [[ -n "$sid" ]]; then
		printf '%s\n' "$sid" >"$STATE_FILE"
	fi

	if [[ -z "$result" ]]; then
		cat "$out"
		rm -f "$out" "$err"
		exit "${status:-1}"
	fi

	if [[ "$is_error" == "true" ]]; then
		printf '%s\n' "$result" >&2
		rm -f "$out" "$err"
		exit 1
	fi

	if [[ -n "$pager" ]]; then
		$pager <<<"$result"
	elif command -v bat >/dev/null && [[ -t 1 ]]; then
		bat --language markdown --paging never --style plain <<<"$result"
	else
		printf '%s\n' "$result"
	fi
else
	cat "$out"
fi

rm -f "$out" "$err"
