#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [-r] <file-or-dir>"
  echo "  -r    recurse into subdirectories"
  exit 1
}

recursive=false
while getopts "r" opt; do
  case "$opt" in
    r) recursive=true ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

if [[ $# -ne 1 ]]; then
  usage
fi
TARGET="$1"

if sed --version >/dev/null 2>&1; then
  SED_INPLACE=( -i )
else
  SED_INPLACE=( -i '' )
fi

process_file() {
  local file="$1"
  # Only change if first line is exactly "#!/bin/bash"
  if head -n1 "$file" | grep -q '^#!/bin/bash$'; then
    sed "${SED_INPLACE[@]}" '1s|^#!/bin/bash$|#!/usr/bin/env bash|' "$file"
    echo "✔ Updated shebang in: $file"
  fi
}

if [[ -f "$TARGET" ]]; then
  # Just a single file
  process_file "$TARGET"

elif [[ -d "$TARGET" ]]; then
  # Directory: choose find parameters based on -r
  if $recursive; then
    find_args=( "$TARGET" -type f \( -name '*.sh' -o -name '*.bash' \) )
  else
    find_args=( "$TARGET" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.bash' \) )
  fi

  # Loop through matching files
  find "${find_args[@]}" -print0 |
    while IFS= read -r -d '' file; do
      process_file "$file"
    done

else
  echo "Error: '$TARGET' is not a file or directory." >&2
  exit 1
fi

