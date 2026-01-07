#!/usr/bin/env bash

USE_FZF=false

[[ "$1" == "--cli" ]] && USE_FZF=true

if command -v fd >/dev/null 2>&1; then
  PDFS=$(fd -e pdf -t f . "$HOME" | sed "s|^$HOME/||")
else
  PDFS=$(find "$HOME" -type f -name "*.pdf" -printf "%P\n")
fi

SELECTED=$(
  if $USE_FZF; then
     echo "$PDFS"| fzf --preview "pdftotext -- $HOME/{} - | head -40"
  else
    echo "$PDFS" | tofi --width 50% --prompt "Select PDF: "
  fi
)

[[ -n "$SELECTED" ]] && zathura "$HOME/$SELECTED"

