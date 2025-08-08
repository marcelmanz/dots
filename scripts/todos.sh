#!/usr/bin/env bash

# -----------------------------
# Usage: ./script.sh [-i]
#   -i       Ignore local TODO.md and always use the daily notes
#   offset   0 (default) = today, -1 = yesterday, -2 = two days ago,
# -----------------------------

ignore_local=0
offset=0
for arg in "$@"; do
  if [[ $arg =~ ^-[0-9]+$ ]]; then
    offset=$arg
    shift
    break
  fi
done

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
shift $((OPTIND - 1))

if ! [[ $offset =~ ^-?[0-9]+$ ]]; then
  echo "Offset must be an integer" >&2
  exit 1
fi

# 1) If not ignoring and there's a TODO.md in cwd, open it and exit
if [[ $ignore_local -eq 0 && (-f "./TODO.md" || -f "./todo.md") ]]; then
  if [[ -f "./TODO.md" ]]; then
    nvim "./TODO.md"
  else
    nvim "./todo.md"
  fi
  exit 0
fi

cd ~/notes/ || exit 1

current_date=$(date +'%Y-%m-%d')
current_date_todo="TODO:$current_date.md"
previous_date=$(date -d "yesterday" +'%Y-%m-%d')
previous_date_todo="TODO:$previous_date.md"

if ((offset != 0)); then
  mapfile -t todo_files < <(ls -1 TODO:[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md 2>/dev/null | sort -r)
  index=$((-offset))
  if [[ $index -ge ${#todo_files[@]} ]]; then
    echo "No TODO at that offset" >&2
    exit 1
  fi
  nvim "${todo_files[$index]}"
  cd - >/dev/null 2>&1
  exit 0
fi

if [[ ! -f $current_date_todo ]]; then
  touch "$current_date_todo"
  {
    echo "# TODO: $(date +'%Y-%m-%d')"
    echo
    if [[ -f $previous_date_todo ]]; then
      # link to yesterday's TODO
      echo "[[/TODO:$previous_date]]"
      echo
    fi
    echo "- [ ] "
  } >>"$current_date_todo"
fi

nvim "$current_date_todo"

cd - >/dev/null 2>&1
