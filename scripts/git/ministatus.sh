#!/usr/bin/env bash

GREEN=$'\033[32m'
RED=$'\033[31m'
RESET=$'\033[0m'

pass_raw=false

for arg in "$@"; do
  case "$arg" in
  --short | --long | --branch | --ignored | --show-stash | --column| --help*)
    pass_raw=true
    ;;
  esac
done

if $pass_raw; then
  git status "$@"
  exit $?
fi

git status --porcelain "$@" |
  awk -v g="$GREEN" -v r="$RED" -v x="$RESET" '
{
    a = substr($0, 1, 1)
    b = substr($0, 2, 1)
    rest = substr($0, 4)

    if (rest !~ /^\.\/|^\//)
        rest = "./" rest

    printf "%s%s%s%s%s%s %s\n", g, a, x, r, b, x, rest
}
'
