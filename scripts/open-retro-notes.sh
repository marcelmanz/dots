#!/usr/bin/env bash
file=~/notes/retrospectives.md
today=$(date -I)

if ! grep -q "^### $today:" "$file"; then
  sed -i "3i### $today:\n- \n" "$file"
fi

nvim "$file"
