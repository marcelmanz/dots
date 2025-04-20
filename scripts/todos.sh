#!/usr/bin/env bash

# -----------------------------
# Usage: ./script.sh [-i]
#   -i    Ignore local TODO.md and always use the daily notes
# -----------------------------

ignore_local=0
while getopts ":i" opt; do
  case $opt in
    i)
      ignore_local=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# 1) If not ignoring and there's a TODO.md in cwd, open it and exit
if [[ $ignore_local -eq 0 && -f "./TODO.md" ]]; then
  nvim "./TODO.md"
  exit 0
fi

cd ~/notes/ || exit 1

current_date_todo="TODO:$(date +'%Y-%m-%d').md"
previous_date=$(date -d "yesterday" +'%Y-%m-%d')
previous_date_todo="TODO:$previous_date.md"

if [[ ! -f $current_date_todo ]]; then
  touch "$current_date_todo"
  {
    echo "# TODO: $(date +'%Y-%m-%d')"
    echo
    if [[ -f $previous_date_todo ]]; then
      # link to yesterday's TODO
      echo "[[TODO:$previous_date]]"
      echo
    fi
    echo "- [ ] "
  } >> "$current_date_todo"
fi

nvim "$current_date_todo"

cd - >/dev/null 2>&1

