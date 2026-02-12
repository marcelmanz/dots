#!/usr/bin/env bash

FILE="$HOME/notes/practice.txt"

mkdir -p "$(dirname "$FILE")"
touch "$FILE"

compact=0
remove=0
desc=""

args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
    --desc)
        desc="$2"
        shift 2
        ;;
    --compact | -c)
        compact=1
        shift
        ;;
    --remove | -r)
        remove=1
        shift
        ;;
    *)
        args+=("$1")
        shift
        ;;
    esac
done

cmd="${args[*]}"

if [[ -z "$cmd" && $remove -eq 0 && ! -t 0 ]]; then
    read -r line
    cmd="${line%%$'\t'*}"
fi

next_id() {
    awk -F'\t' 'END { print ($1 ? $1 + 1 : 1) }' "$FILE"
}

if [[ -z "$cmd" && $remove -eq 0 ]]; then
    if [[ $compact -eq 1 ]]; then
        cut -f1,2 "$FILE"
    else
        awk -F'\t' '
      {
        printf "[%s] %s\n", $1, $2
        if ($3 != "") {
          printf "    %s\n", $3
        }
        print ""
      }
    ' "$FILE"
    fi
    exit 0
fi

if [[ $remove -eq 1 ]]; then
    grep -v "^$cmd"$'\t' "$FILE" >"$FILE.tmp"
    mv "$FILE.tmp" "$FILE"
    exit 0
fi

if [[ "$cmd" =~ ^[0-9]+$ ]]; then
    awk -F'\t' -v id="$cmd" '
    $1 == id {
      printf "[%s] %s\n", $1, $2
      if ($3 != "") {
        printf "    %s\n", $3
      }
      found=1
    }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "$FILE"
    exit 0
fi

id=$(next_id)
printf "%s\t%s\t%s\n" "$id" "$cmd" "$desc" >>"$FILE"
