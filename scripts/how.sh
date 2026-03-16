#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/how"
STATE_FILE="$STATE_DIR/session"
CACHE_DIR="$STATE_DIR/cache"
mkdir -p "$STATE_DIR" "$CACHE_DIR"

continue=false
no_cache=false
pager=""
query_parts=()

while [[ $# -gt 0 ]]; do
	case "${1:-}" in
	--continue | -c)
		continue=true
		shift
		;;
	--no-cache)
		no_cache=true
		shift
		;;
	--pager)
		pager="$2"
		shift 2
		;;
	*)
		query_parts+=("$1")
		shift
		;;
	esac
done

q="${query_parts[*]}"
if [[ -z "$q" ]]; then
	# if no query is provided show cached queries
	if [[ -t 0 ]] && [[ -t 1 ]]; then
		script_path="$(dirname "$0")/how-get-cache.sh"
		if [[ -x "$script_path" ]]; then
			exec "$script_path"
		elif command -v how-get-cache.sh >/dev/null 2>&1; then
			exec how-get-cache.sh
		else
			echo "how-get-cache.sh not found. Please install it." >&2
			exit 1
		fi
	else
		q="$(cat)"
	fi
fi

query_hash="$(printf '%s' "$q" | sha256sum | cut -d' ' -f1)"
cache_file="$CACHE_DIR/$query_hash"

if [[ -f "$cache_file" ]] && ! $continue && ! $no_cache; then
	if [[ -n "$pager" ]]; then
		$pager <"$cache_file"
	elif command -v bat >/dev/null && [[ -t 1 ]]; then
		bat --language markdown --paging never --style plain <"$cache_file"
	else
		cat "$cache_file"
	fi
	exit 0
fi

out="$(mktemp)"
err="$(mktemp)"

if $continue && [[ -f "$STATE_FILE" ]]; then
	sid="$(cat "$STATE_FILE")"
	cmd=(opencode run --format json --model synthetic/hf:zai-org/GLM-4.7 --session "$sid")
else
	cmd=(opencode run --format json --model synthetic/hf:zai-org/GLM-4.7)
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

sid="$(jq -r 'select(.sessionID!=null) | .sessionID' <"$out" | head -n1)"
result="$(jq -r 'select(.type=="text") | .part.text' <"$out")"
error="$(jq -r 'select(.type=="error") | .error.message' <"$out")"

if [[ -n "$sid" ]]; then
	printf '%s\n' "$sid" >"$STATE_FILE"
fi

if [[ -n "$error" ]]; then
	printf '%s\n' "$error" >&2
	rm -f "$out" "$err"
	exit 1
fi

if [[ -z "$result" ]]; then
	cat "$out"
	rm -f "$out" "$err"
	exit "${status:-1}"
fi

printf '%s\n' "$result" >"$cache_file"

if [[ -n "$pager" ]]; then
	$pager <<<"$result"
elif command -v bat >/dev/null && [[ -t 1 ]]; then
	bat --language markdown --paging never --style plain <<<"$result"
else
	printf '%s\n' "$result"
fi

rm -f "$out" "$err"
