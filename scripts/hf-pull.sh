#!/usr/bin/env bash

selected=$(~/scripts/hf-search.py | fzf)

if [ -z "$selected" ]; then
    echo "No model selected"
    exit 0
fi

llama-cli -hf "$selected"
