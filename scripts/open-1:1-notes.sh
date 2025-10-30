#!/usr/bin/env bash
file=~/notes/1:1.md
today=$(date -I)

if ! grep -q "^### $today:" "$file"; then
  sed -i "3i### $today:\n- \n" "$file"
fi

nvim "$file"
