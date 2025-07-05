#!/usr/bin/env bash
set -euo pipefail

REPO="${DEV_TEMPLATES:-$HOME/clones/own/dev-templates}"

edit=false
remote=""
lang=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	-e | --edit)
		edit=true
		shift
		;;
	-r | --remote)
		remote="$2"
		shift 2
		;;
	*)
		lang="$1"
		shift
		;;
	esac
done

if [[ -n "$remote" ]]; then
	if [[ -z "$lang" ]]; then
		if [[ $remote =~ ^github: ]]; then
			gh="${remote#github:}"
			owner="${gh%%/*}"
			repo="${gh#*/}"
			api="https://api.github.com/repos/${owner}/${repo}/contents"
			lang=$(curl -fsSL "$api" | jq -r '.[] | select(.type=="dir") | .name' | grep -v '^\.github$' | fzf)
		else
			echo "fzf selection only supported for github: remotes" >&2
			exit 1
		fi
	fi
	[[ -z "$lang" ]] && exit 0
	$edit && echo "--edit ignored with --remote" >&2
	exec nix develop "${remote}?dir=${lang}"
fi

if [[ -z "$lang" ]]; then
	lang=$(git -C "$REPO" ls-tree -d --name-only HEAD | grep -v '^\.github$' | fzf)
fi
[[ -z "$lang" ]] && exit 0

flake="$REPO/$lang/flake.nix"
if $edit; then
	"${EDITOR:-vi}" "$flake"
fi

exec nix develop "$REPO/$lang"
