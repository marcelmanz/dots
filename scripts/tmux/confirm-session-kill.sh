#!/usr/bin/env bash

current_session=$(tmux display-message -p '#S')

tmux display-popup -E -w 70 -h 10 "choice=\$(printf 'Cancel\nKill' | fzf --prompt='Kill session \"$current_session\"? ' --height 40% --border --color=fg:#ffffff,bg:#000000,hl:#ff0000 --ansi); if [[ \$choice == 'Kill' ]]; then tmux kill-session -t '$current_session'; fi"
