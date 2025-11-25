#!/usr/bin/env bash

use_tofi="$1"

base=~/scripts
all_scripts=$(find -L "$base" -type f ! -name '.*')

if [ "$use_tofi" = "--tofi" ]; then
	selected=$(printf '%s\n' "$all_scripts" |
		sed "s|^$base/||" |
		tofi)
else
	selected=$(printf '%s\n' "$all_scripts" |
		sed "s|^$base/||" |
		fzf --preview "bat --style=plain --color=always $base/{}")
fi

[ -z "$selected" ] && exit 0

"$base/$selected"
