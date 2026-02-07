#!/usr/bin/env bash

store="$HOME/.password-store"

selected=$(
	cd "$store" || exit
	find . -type f -name '*.gpg' |
		sed 's|^\./||; s|\.gpg$||' |
		fzf
)

[ -n "$selected" ] && pass show "$selected"
