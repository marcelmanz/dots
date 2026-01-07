#!/usr/bin/env bash

USE_FZF=false
SEARCH_DIRS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cli) USE_FZF=true ;;
    --dirs) SEARCH_DIRS=true ;;
    *) ;;
  esac
  shift
done

VIDEO_EXTS="mkv|mp4|webm|avi|mov|flv|wmv|m4v|ts|mts|m2ts|mxf|ogv|3gp|asf|rmvb"

if $SEARCH_DIRS; then
  if command -v fd >/dev/null 2>&1; then
    RESULTS=$(fd -t d . "$HOME" | sed "s|^$HOME/||")
  else
    RESULTS=$(find "$HOME" -type d | sed "s|^$HOME/||")
  fi
  PROMPT="Select Folder: "
else
  if command -v fd >/dev/null 2>&1; then
    RESULTS=$(fd -t f . "$HOME" | grep -iE "\.($VIDEO_EXTS)$" | sed "s|^$HOME/||")
  else
    RESULTS=$(find "$HOME" -type f | grep -iE "\.($VIDEO_EXTS)$" | sed "s|^$HOME/||")
  fi
  PROMPT="Select Video: "
fi

SELECTED=$(
  if $USE_FZF; then
     echo "$RESULTS" | fzf --preview "ls -lh \"$HOME/{}\""
  else
    echo "$RESULTS" | tofi --width 50% --prompt "$PROMPT"
  fi
)

[[ -n "$SELECTED" ]] && mpv "$HOME/$SELECTED"

