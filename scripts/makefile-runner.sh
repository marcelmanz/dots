#!/usr/bin/env bash

makefile_path='Makefile'
make_targets=$(make -pRrq | awk -F ':' '/^[a-zA-Z0-9_-]+:/ && !/^#/ && $1 != "Makefile"{print $1}')

selected=($(echo "$make_targets" | fzf --preview "
  awk '
    /^{}:/ {print; found=1; next} 
    found && /^[[:space:]]+/ {print} 
    found && /^[^[:space:]]/ {exit} 
  ' $makefile_path" -m))

num_targets=${#selected[@]}

if [[ $num_targets -eq 0 ]]; then
	echo "No targets selected."
	exit 1
fi

tmux select-layout main-horizontal

for i in "${!selected[@]}"; do
	if [[ $i -eq 0 ]]; then
		tmux send-keys "make ${selected[i]}" C-m
	else
		tmux split-window -h "make ${selected[i]}; read"
	fi
done

tmux select-layout main-horizontal
