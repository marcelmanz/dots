
SESSION_NAME="tty-tmux"

if tmux has-session -t $SESSION_NAME 2>/dev/null; then
	tmux attach -t $SESSION_NAME
else
	tmux new-session -s $SESSION_NAME -n "tty" -d
	tmux attach -t $SESSION_NAME
fi
