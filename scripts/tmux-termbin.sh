#!/usr/bin/env bash

INPUT=$(cat)
URL=$(echo "$INPUT" | nc termbin.com 9999)

tmux display-message "Uploaded to: $URL"
