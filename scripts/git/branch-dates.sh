#!/usr/bin/env bash
# `git branch` with creation and last-commit dates. With args, plain `git branch "$@"`.
# Creation date is the oldest reflog entry, so it is local-only and "-" once the reflog expires.
set -euo pipefail

if (($#)); then
	exec git branch "$@"
fi

git_dir=$(git rev-parse --git-common-dir)

spinner_pid=""
stop_spinner() {
	[[ -n $spinner_pid ]] || return 0
	kill "$spinner_pid" 2>/dev/null || true
	wait "$spinner_pid" 2>/dev/null || true
	spinner_pid=""
	printf '\r\e[K' >&2
}
if [[ -t 2 ]]; then
	(
		frames='-\|/'
		i=0
		while :; do
			printf '\r%s' "${frames:i++%4:1}" >&2
			sleep 0.1
		done
	) &
	spinner_pid=$!
	trap stop_spinner EXIT
fi

heads=() names=() updated=() updated_relative=()
width=0
output=""
while IFS=$'\t' read -r head name date relative; do
	heads+=("$head") names+=("$name") updated+=("$date") updated_relative+=("$relative")
	((${#name} > width)) && width=${#name}
done < <(git for-each-ref --sort=refname \
	--format='%(HEAD)%09%(refname:short)%09%(committerdate:format:%Y-%m-%d)%09%(committerdate:relative)' \
	refs/heads)

for i in "${!names[@]}"; do
	created=-
	reflog="$git_dir/logs/refs/heads/${names[i]}"
	if [[ -r $reflog ]] && IFS=$'\t' read -r entry _ <"$reflog"; then
		read -r timestamp _ <<<"${entry##*>}"
		[[ $timestamp =~ ^[0-9]+$ ]] && printf -v created '%(%Y-%m-%d)T' "$timestamp"
	fi
	color=""
	[[ ${heads[i]} == "*" ]] && color=$'\e[32m'
	printf -v line '%s %s%-*s\e[0m  \e[2mcreated\e[0m %-10s  \e[2mupdated\e[0m %s \e[2m(%s)\e[0m\n' \
		"${heads[i]}" "$color" "$width" "${names[i]}" "$created" "${updated[i]}" "${updated_relative[i]}"
	output+=$line
done

stop_spinner
printf '%s' "$output"
