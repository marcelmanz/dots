#!/usr/bin/env bash
set -uo pipefail

# fuzzy menu of open tmux sessions, local + remote. remote hosts probed in
# parallel from recent ssh history (atuin); BatchMode + short timeout so
# key-only hosts never hang. remote lines shown as host:session, local bare.

# local sessions
lines=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)

# remote: top recent ssh hosts
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

# ponytail: dedup by remote hostname #H — mlab (WAN) and mlab-local (LAN) are
# one box; both report #H=mlab, so collapse to a single entry. atuin frequency
# order surfaces the most-used alias first (usually LAN), which wins.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
i=0
for h in $hosts; do
    (
        timeout 4 ssh -o ConnectTimeout=2 -o BatchMode=yes "$h" \
            "tmux list-sessions -F '#H|#{session_name}'" 2>/dev/null |
            while IFS='|' read -r H s; do
                [ -n "$H" ] && printf '%s|%s|%s\n' "$h" "$H" "$s"
            done
    ) > "$tmp/$i" &
    i=$((i + 1))
done
wait || true

declare -A seen=()
for f in "$tmp"/*; do
    [ -f "$f" ] || continue
    while IFS='|' read -r alias H s; do
        [ -n "${H:-}" ] && [ -n "${s:-}" ] || continue
        key="$H|$s"
        [ -n "${seen[$key]:-}" ] && continue
        seen[$key]=1
        lines=$(printf '%s\n%s:%s' "$lines" "$alias" "$s")
    done < "$f"
done

pick=$(printf '%s\n' "$lines" | sed '/^$/d' | fzf --prompt='attach> ')
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
