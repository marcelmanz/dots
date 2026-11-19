#!/usr/bin/env bash

function CheckUpdates() {
updates="$(checkupdates;paru -Qum)"
arch="$(checkupdates | wc -l)"
aur="$(paru -Qum | wc -l)"
number=$((arch+aur))

if [ "$number" -gt 0 ]; then
    text=" $number"
else
    text=""
fi

echo "$text"
}

function RefreshUpdates() {
  value="$(CheckUpdates)"
  eww update arch-updates="$value"
}

function Update() {
	alacritty -e paru
	RefreshUpdates
}

case "$1" in
        Refresh)
            RefreshUpdates
	    exit 0
            ;;
	Update)
            Update
	    exit 0
	    ;;
        *)
            CheckUpdates
            exit 0 
esac
