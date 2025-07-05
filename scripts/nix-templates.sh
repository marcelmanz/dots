#!/usr/bin/env bash
set -euo pipefail

REPO="${DEV_TEMPLATES:-$HOME/clones/own/dev-templates}"

edit=false
lang=""
while [[ $# -gt 0 ]]; do
	case "$1" in
	-e | --edit)
		edit=true
		shift
		;;
	*)
		lang="$1"
		shift
		;;
	esac
done

if [[ -z "$lang" ]]; then
	lang=$(git -C "$REPO" ls-tree -d --name-only HEAD | grep -v '^\.github$' | fzf)
fi

[ -n "$lang" ] || exit 0

flake="$REPO/$lang/flake.nix"

if $edit; then
	"${EDITOR:-vi}" "$flake"
fi

exec nix develop "$REPO/$lang"
