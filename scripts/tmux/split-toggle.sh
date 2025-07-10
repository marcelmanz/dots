#!/usr/bin/env bash

FLAG=$(tmux show-options -w -v @exploded 2>/dev/null || echo "")

if [ "$FLAG" = "1" ]; then
	~/scripts/tmux/split-implode.sh
else
	~/scripts/tmux/split-explode.sh
fi
