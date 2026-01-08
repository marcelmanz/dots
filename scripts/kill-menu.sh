#!/usr/bin/env bash

set -euo pipefail

if ! command -v fzf &>/dev/null; then
    echo "fzf is not installed"
    exit 1
fi

process_name=$(ps aux | awk 'NR>1 {print $11}' | sed 's:.*/::' | sort -u | fzf --prompt="Select process: " --height=40%)

if [ -z "$process_name" ]; then
    echo "No process selected"
    exit 0
fi

pids=($(pgrep -x "$process_name" 2>/dev/null || pgrep -f "$process_name" 2>/dev/null || true))

if [ ${#pids[@]} -eq 0 ]; then
    echo "No running processes found for: $process_name"
    exit 1
fi

if [ ${#pids[@]} -eq 1 ]; then
    pid=${pids[0]}
    cmd=$(ps -p "$pid" -o cmd= 2>/dev/null || echo "unknown")
    echo "Found 1 process: $process_name (PID: $pid)"
    echo "Command: $cmd"
    read -p "Kill this process? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kill "$pid"
        echo "Killed PID $pid"
    fi
else
    options=("Kill All (${#pids[@]} processes)")
    for pid in "${pids[@]}"; do
        cmd=$(ps -p "$pid" -o cmd= 2>/dev/null || echo "unknown")
        options+=("PID: $pid - $cmd")
    done

    printf '%s\n' "${options[@]}" | fzf --prompt="Select target: " --height=40% | {
        read -r selection

        if [[ "$selection" == "Kill All"* ]]; then
            echo "Killing all $process_name processes: ${pids[*]}"
            read -p "Confirm kill all? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                kill "${pids[@]}"
                echo "Killed all processes"
            fi
        else
            pid=$(echo "$selection" | awk '{print $2}')
            echo "Killing PID $pid"
            read -p "Confirm? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                kill "$pid"
                echo "Killed PID $pid"
            fi
        fi
    }
fi
