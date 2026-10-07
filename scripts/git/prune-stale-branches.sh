#!/usr/bin/env bash
set -e

days="${1:-30}"
now=$(date +%s)
current=$(git symbolic-ref -q --short HEAD)
default=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
default=${default#origin/}
default="${default:-$current}"

stale=()
while IFS=$'\t' read -r branch epoch; do
	[[ "$branch" == "$current" || "$branch" == "$default" ]] && continue
	age_days=$(((now - epoch) / 86400))
	[[ "$age_days" -lt "$days" ]] && continue
	stale+=("$branch")
done < <(git for-each-ref --format='%(refname:short)%09%(committerdate:unix)' refs/heads/)

if [[ ${#stale[@]} -eq 0 ]]; then
	echo "No branches older than $days days."
	exit 0
fi

echo "Branches with no commits in $days+ days:"
{
	echo -e "BRANCH\tLAST COMMIT\tUNIQUE TO BRANCH\tMISSING FROM BRANCH"
	for branch in "${stale[@]}"; do
		read -r behind ahead < <(git rev-list --left-right --count "$default...$branch")
		last=$(git log -1 --format='%ar' "$branch")
		echo -e "$branch\t$last\t$ahead\t$behind"
	done
} | column -t -s $'\t'

read -rp "Delete these ${#stale[@]} branch(es)? [y/N] " reply
[[ "$reply" =~ ^[Yy]$ ]] || exit 0

for branch in "${stale[@]}"; do
	git branch -D "$branch"
done
