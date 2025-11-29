#!/usr/bin/env bash

# Get current window and pane
current_window=$(tmux display-message -p '#I')
current_pane=$(tmux display-message -p '#P')

# Get all windows
windows=$(tmux list-windows -F '#{window_index}')

output=""

for window in $windows; do
    # Count panes in this window
    pane_count=$(tmux list-panes -t "$window" | wc -l)

    if [ "$pane_count" -gt 1 ]; then
        # Multiple panes: show each pane
        while read -r pane_index command; do
            if [ "$window" = "$current_window" ] && [ "$pane_index" = "$current_pane" ]; then
                output+="#[fg=#698DDA,bold]${window}:${pane_index}:${command}#[default] "
            else
                output+="${window}:${pane_index}:${command} "
            fi
        done < <(tmux list-panes -t "$window" -F '#{pane_index} #{pane_current_command}')
    else
        # Single pane: show just window:command
        command=$(tmux list-panes -t "$window" -F '#{pane_current_command}' | head -1)
        if [ "$window" = "$current_window" ]; then
            output+="#[fg=#698DDA,bold]${window}:${command}#[default] "
        else
            output+="${window}:${command} "
        fi
    fi
done

echo "$output"
