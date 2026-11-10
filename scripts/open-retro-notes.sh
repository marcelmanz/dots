#!/usr/bin/env bash
file=~/notes/retrospectives.md
today=$(date -I)

awk '
  function flush() { if (has_content) printf "%s", section; section = ""; has_content = 0 }
  /^### / { flush(); in_section = 1 }
  !in_section { print; next }
  { section = section $0 "\n" }
  !/^-?[[:space:]]*$/ && !/^### / { has_content = 1 }
  END { flush() }
' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

if ! grep -q "^### $today:" "$file"; then
  line=$(grep -n "^### " "$file" | head -1 | cut -d: -f1)
  line=${line:-$(($(wc -l < "$file") + 1))}
  sed -i "${line}i### $today:\n- \n" "$file"
fi

nvim "$file"
