#!/usr/bin/env bash

NCHAT_TMUX_SESSION_NAME="nchat"

if ! tmux has-session -t $NCHAT_TMUX_SESSION_NAME 2>/dev/null; then
	tmux new-session -d -s $NCHAT_TMUX_SESSION_NAME
	tmux send-keys -t $NCHAT_TMUX_SESSION_NAME "nchat" C-m
fi

# if we are inside a tmux session move to the nchat one
if [ -n "$TMUX" ]; then
	tmux switch-client -t $NCHAT_TMUX_SESSION_NAME
	exit
fi

tmux attach -t $NCHAT_TMUX_SESSION_NAME

