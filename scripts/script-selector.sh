#!/usr/bin/env bash

use_tofi="$1"

if [ "$use_tofi" = "--tofi" ]; then
	shift
fi

base=~/scripts
all_scripts=$(find -L "$base" -type f ! -name '.*')

if [ "$use_tofi" = "--tofi" ]; then
	selected=$(printf '%s\n' "$all_scripts" |
		sed "s|^$base/||" |
		tofi --fuzzy-match=true --prompt-text "Run script: ")
else
	selected=$(printf '%s\n' "$all_scripts" |
		sed "s|^$base/||" |
		fzf \
			--bind "ctrl-e:execute($EDITOR $base/{})" \
			--preview "bat --style=plain --color=always $base/{}")

fi

[ -z "$selected" ] && exit 0

args_input=""
if [ "$use_tofi" = "--tofi" ]; then
	args_input=$(printf '\n' | tofi --height 40 --prompt-text "Add args (optional): " --require-match=false)
else
	read -r -p "args (optional)> " args_input
fi

if [ -n "$args_input" ]; then
	read -r -a extra_args <<<"$args_input"
	"$base/$selected" "${extra_args[@]}"
else
	"$base/$selected"
fi
