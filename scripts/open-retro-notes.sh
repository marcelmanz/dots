#!/usr/bin/env bash
file=~/notes/retrospectives.md
today=$(date -I)

if ! grep -q "^### $today:" "$file"; then
  line=$(grep -n "^### " "$file" | head -1 | cut -d: -f1)
  line=${line:-$(($(wc -l < "$file") + 1))}
  sed -i "${line}i### $today:\n- \n" "$file"
fi

nvim "$file"
