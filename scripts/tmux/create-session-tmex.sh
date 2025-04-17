#!/usr/bin/env sh

SESSION_TYPE=$1

if [ -z "$SESSION_TYPE" ]; then
	echo "No session type provided"
	echo "Select a session type:"
	SESSION_TYPE=$(ls $HOME/clones | fzy)
fi

WORK_PATH="$HOME/clones/$SESSION_TYPE"
# Selecting a repository to work on
SELECTED_REPO=$(ls "$WORK_PATH" | fzy)
REPO=$(echo $SELECTED_REPO | sed 's/\//-/g' | sed 's/\./-dot-/g')
SESSION="$SESSION_TYPE-$REPO"
REPO_NAME="$WORK_PATH/$SELECTED_REPO/"
EDITOR=nvim
# SHELL=fish # Already set in tmux.conf
# CUSTOM_COMMAND="fnm use"

tmex "$SESSION" --reattach --focus=0 --layout="2{41}" \
	"cd $REPO_NAME; clear; $EDITOR;" \
	"cd $REPO_NAME; clear;"

~/.config/tmux/plugins/tpm/tpm
