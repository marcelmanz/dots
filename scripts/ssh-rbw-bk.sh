#!/usr/bin/env bash
# Back up every ~/.ssh keypair to Bitwarden via rbw.
# pub key  -> password field (one line, easy to re-register)
# priv key -> note
# Skips entries that already exist.
set -euo pipefail

cd ~/.ssh
rbw unlocked >/dev/null 2>&1 || {
    echo "run: rbw unlock"
    exit 1
}

STAGED="$(mktemp)"
EDITOR_SH="$(mktemp)"
printf '#!/usr/bin/env bash\ncat "%s" > "$1"\n' "$STAGED" >"$EDITOR_SH"
chmod +x "$EDITOR_SH"
trap 'rm -f "$STAGED" "$EDITOR_SH"' EXIT

count=0
for priv in *; do
    [ -f "$priv" ] || continue
    [ -f "$priv.pub" ] || continue # only real keypairs (skips config, known_hosts, etc.)

    name="ssh/$priv"
    if rbw get "$name" >/dev/null 2>&1; then
        echo "skip (exists): $name"
        continue
    fi

    {
        cat "$priv.pub"
        echo
        cat "$priv"
    } >"$STAGED" # line1=pub, rest=private
    EDITOR="$EDITOR_SH" VISUAL="$EDITOR_SH" rbw add "$name"
    echo "added: $name"
    count=$((count + 1))
done

echo "done: $count added"
