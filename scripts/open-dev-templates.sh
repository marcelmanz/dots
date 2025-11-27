#!/usr/bin/env bash

DEV_TEMP_PATH=~/clones/own/dev-templates

dirs=$(find "$DEV_TEMP_PATH" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf "%f\n")
selected=$(printf "%s\n" "$dirs" | fzf)

[ -z "$selected" ] && exit

nvim -c "cd $DEV_TEMP_PATH" "$DEV_TEMP_PATH/$selected/flake.nix"
