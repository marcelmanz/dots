#!/usr/bin/env bash
set -uo pipefail

# fuzzy menu of open tmux sessions. local sessions show the instant fzf opens;
# remote hosts are probed async in parallel and stream in as each responds.
# dedup by remote hostname #H so aliases to one box (mlab / mlab-local) collapse.

# top recent ssh hosts (atuin frequency order)
hosts=$(atuin search --cmd-only 'ssh ' 2>/dev/null |
    awk '
        /^ssh[[:space:]]/ {
            for (i = 2; i <= NF; i++) {
                t = $i
                if (t ~ /^-/) continue
                if (t ~ /[\/:]/) continue
                if (t ~ /@/ || t ~ /\./ || t ~ /^[a-z][a-z0-9_-]+$/) { print t; break }
            }
        }' |
    grep -viE 'localhost|127\.0\.0\.1' |
    sort | uniq -c | sort -rn |
    awk '{ $1 = ""; sub(/^ /, ""); print }' |
    head -8)

# producer: local (now) + one bg job per host (streams alias|#H|session as it
# responds). the pipe stays open until the last bg ssh exits → fzf keeps
# appending. ponytail: dedup key is #H|session; first responder wins. both
# mlab aliases reach the same box, so the race is harmless — re-run flips it.
# swap for explicit LAN-preference if you want deterministic low-latency attach.
pick=$(
    {
        tmux list-sessions -F '#{session_name}' 2>/dev/null || true
        for h in $hosts; do
            timeout 4 ssh -o ConnectTimeout=2 -o BatchMode=yes "$h" \
                "tmux list-sessions -F '#H|#{session_name}'" 2>/dev/null |
                awk -v a="$h" 'NF { print a "|" $0 }' &
        done
    } | awk -F'|' '
        NF == 1 { print; fflush(); next }
        {
            k = $2 "|" $3
            if (k in seen) next
            seen[k] = 1
            print $1 ":" $3
            fflush()
        }
    ' | fzf --prompt='attach> '
)
[ -z "${pick:-}" ] && exit 0

case "$pick" in
    *:*)
        host=${pick%%:*}
        session=${pick#*:}
        exec ssh -t "$host" "tmux attach -t '$session'"
        ;;
    *)
        if [ -n "${TMUX-}" ]; then
            tmux switch-client -t "$pick"
        else
            tmux attach -t "$pick"
        fi
        ;;
esac
