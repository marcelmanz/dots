#!/usr/bin/env bash
set -euo pipefail

# fuzzy menu over recent/saved ssh targets from shell history (atuin)
host="${1:-}"
if [ -z "$host" ]; then
    host=$(
        atuin search --cmd-only 'ssh ' 2>/dev/null |
            awk '
                /^ssh[[:space:]]/ {
                    for (i = 2; i <= NF; i++) {
                        t = $i
                        if (t ~ /^-/) continue
                        if (t ~ /[\/:]/) continue
                        if (t ~ /@/ || t ~ /\./ || t ~ /^[a-z][a-z0-9_-]+$/) { print t; break }
                    }
                }' |
            sort | uniq -c | sort -rn |
            awk '{ $1 = ""; sub(/^ /, ""); print }' |
            fzf --print-query --prompt='ssh host> ' |
            tail -n1
    )
fi
[ -z "${host:-}" ] && exit 0

# ponytail: launcher mode — no nesting, single tmux = remote one. remote
# tmux copy still reaches the local clipboard via OSC 52 (set-clipboard on in
# shared dots tmux.conf). re-run the script to switch hosts.
exec ssh -t "$host" 'tmux new -A -s main'
