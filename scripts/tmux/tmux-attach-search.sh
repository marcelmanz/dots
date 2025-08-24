

if [ $# -eq 0 ]; then
	echo "Usage: $0 <folder1> [folder2] [folder3] ..."
	echo "Example: $0 own work other"
	exit 1
fi

SESSIONS_LIST=$(tmux ls 2>/dev/null)
NO_SERVER_REGEX='^no server running on /tmp/tmux-\d/default'

if [ -z "$SESSIONS_LIST" ] || [[ "$SESSIONS_LIST" =~ $NO_SERVER_REGEX ]]; then
	printf "No sessions found\n"
	read -p "Do you wish to start a session? Answer Y or N " yn
	case $yn in
	[Yy]*)
		ALL_OPTIONS=""
		for folder in "$@"; do
			folder_list=$(ls -d "$HOME/clones/$folder"/*/ 2>/dev/null)
			ALL_OPTIONS+=$(printf "%s\n" "$folder_list" | sed "s|$HOME/clones/||g" | sed 's|/$||g')
		done

		SELECTED=$(printf "$ALL_OPTIONS" | fzf)

		if [ -n "$SELECTED" ]; then
			SESSION_TYPE=$(echo "$SELECTED" | cut -d'/' -f1)
			SESSION_NAME=$(echo "$SELECTED" | cut -d'/' -f2- | sed 's/^ *//')

			tmux new-session -s "$SESSION_TYPE-$SESSION_NAME" 
		else
			echo "Exit"
		fi
		;;
	[Nn]*) exit 1 ;;
	*) printf "Please answer yes or no.\n" ;;
	esac
fi

if [ -n "$SESSIONS_LIST" ] && ! [[ "$SESSIONS_LIST" =~ $NO_SERVER_REGEX ]]; then
	SELECTED_SESSION=$(echo "$SESSIONS_LIST" | awk '{print $1}' | sed 's/://' | fzy)
	
	tmux attach -t "$SELECTED_SESSION"
	exit 0
fi
