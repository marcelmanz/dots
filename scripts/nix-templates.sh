#!/usr/bin/env bash
set -euo pipefail

REPO="${DEV_TEMPLATES:-$HOME/clones/own/dev-templates}"

edit=false
remote=""
lang=""
add_envrc=false

declare -A ext_to_lang=(
	[py]=python
	[js]=javascript
	[jsx]=javascript
	[ts]=typescript
	[tsx]=typescript
	[rb]=ruby
	[go]=go
	[rs]=rust
	[java]=java
	[c]=c
	[cpp]=cpp
	[cc]=cpp
	[cxx]=cpp
	[h]=c
	[hpp]=cpp
	[cs]=csharp
	[php]=php
	[swift]=swift
	[kt]=kotlin
	[kts]=kotlin
	[m]=objective-c
	[mm]=objective-c++
	[scala]=scala
	[hs]=haskell
	[erl]=erlang
	[ex]=elixir
	[exs]=elixir
	[dart]=dart
	[sh]=shell
	[bash]=shell
	[zsh]=shell
	[ps1]=powershell
	[psm1]=powershell
	[lua]=lua
	[pl]=perl
	[pm]=perl
	[groovy]=groovy
	[r]=r
	[jl]=julia
	[sql]=sql
	[yml]=yaml
	[yaml]=yaml
	[json]=json
	[xml]=xml
	[html]=html
	[css]=css
	[scss]=scss
	[md]=markdown
)

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
	-d | --direnv)
		add_envrc=true
		shift
		;;
	*)
		lang="$1"
		shift
		;;
	esac
done

if [[ -n "${ext_to_lang[$lang]:-}" ]]; then
	lang=${ext_to_lang[$lang]}
fi

if $add_envrc; then
	echo "ADDING ENVRC"
	if [[ -n "$remote" ]]; then
		echo "use flake \"${remote}?dir=${lang}\"" >.envrc
	else
		echo "use flake \"${REPO}/${lang}\"" >.envrc
	fi
	echo ".envrc created, run 'direnv allow' to enable it"
	exit 0
fi

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
