#!/usr/bin/env bash

# 1. branch
branch=$(git symbolic-ref -q --short HEAD) || {
	echo "Not on a branch"
	exit 1
}

# 2. remote info
remote=$(git config --get remote.origin.url)
url=${remote#git@}  # strip "git@"
url=${url/:/\/}     # turn ":" into "/"
url=${url#https://} # strip https://
url=${url%.git}     # strip trailing .git
host=${url%%/*}     # e.g. github.com
path=${url#*/}      # e.g. user/repo or ws/project

open_url() {
	if command -v open &>/dev/null; then
		open "$1"
	else
		xdg-open "$1"
	fi
}

case "$host" in

# — GitHub —
github.com)
	# look up PR by API
	pr_num=$(curl -s "https://api.github.com/repos/$path/pulls?head=$(echo $path | cut -d/ -f1):$branch" |
		grep -m1 '"number":' |
		sed -E 's/.*"number":[[:space:]]*([0-9]+).*/\1/')
	if [[ -n "$pr_num" ]]; then
		open_url "https://$host/$path/pull/$pr_num"
	else
		echo "No GitHub PR exists for branch '$branch'."
	fi
	;;

# — GitLab (.com or self-hosted) —
gitlab.com | gitlab.*)
	# note: if self-hosted on HTTPS with custom port, this still works
	pr_iid=$(curl -s "https://$host/api/v4/projects/$(printf '%s' "$path" | sed 's#/#%2F#g')/merge_requests?source_branch=$branch" |
		grep -m1 '"iid":' |
		sed -E 's/.*"iid":[[:space:]]*([0-9]+).*/\1/')
	if [[ -n "$pr_iid" ]]; then
		open_url "https://$host/$path/-/merge_requests/$pr_iid"
	else
		echo "No GitLab MR exists for branch '$branch'."
	fi
	;;

# — Bitbucket Cloud —
bitbucket.org)
	pr_id=$(curl -s "https://api.bitbucket.org/2.0/repositories/$path/pullrequests?q=source.branch.name=\"$branch\"" |
		grep -m1 '"id":' |
		sed -E 's/.*"id":[[:space:]]*([0-9]+).*/\1/')
	if [[ -n "$pr_id" ]]; then
		open_url "https://$host/$path/pull-requests/$pr_id"
	else
		echo "No Bitbucket PR exists for branch '$branch'."
	fi
	;;

*)
	echo "⚠️  Unsupported host: $host"
	exit 1
	;;
esac
