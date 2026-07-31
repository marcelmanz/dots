#!/usr/bin/env bash
# Port every pass(1) entry into Bitwarden via rbw.
#   pass line 1    -> rbw password
#   pass rest      -> rbw notes
#   first segment  -> rbw folder; remainder -> name (root entries: no folder)
# Skips + warns on entries rbw can't faithfully store:
#   - notes with a line starting at column 1 with '#' (rbw strips these as comments)
#   - notes >7000 chars (rbw API 400s; Bitwarden's web UI accepts up to ~10000)
# Both cases: add manually via the Bitwarden web UI (notes textarea has no such limits).
# Idempotent (exact name+folder match skips). Plaintext is piped pass->rbw, never displayed.
set -euo pipefail

log() { printf '%s\n' "$*" >&2; }

for cmd in pass rbw jq; do
  command -v "$cmd" >/dev/null 2>&1 || { log "$cmd not found"; exit 1; }
done
rbw unlocked >/dev/null 2>&1 || { log "run: rbw unlock"; exit 1; }

STORE="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
[ -d "$STORE" ] || { log "pass store not found: $STORE"; exit 1; }

INDEX="$(mktemp)"
trap 'rm -f "$INDEX"' EXIT
rbw list --raw > "$INDEX"

exists() { # $1=name $2=folder(empty=root)
  if [ -z "$2" ]; then
    jq -e --arg n "$1" '.[] | select(.name == $n and .folder == null)' "$INDEX" >/dev/null 2>&1
  else
    jq -e --arg n "$1" --arg f "$2" '.[] | select(.name == $n and .folder == $f)' "$INDEX" >/dev/null 2>&1
  fi
}

add=0; skip=0; manual=0; fail=0
while IFS= read -r gpg; do
  rel="${gpg#"$STORE"/}"; rel="${rel%.gpg}"
  if [[ "$rel" == */* ]]; then folder="${rel%%/*}"; name="${rel#*/}"; else folder=""; name="$rel"; fi

  if exists "$name" "$folder"; then
    log "skip (exists): ${folder:+$folder/}$name"; skip=$((skip + 1)); continue
  fi

  # one pass: note char count + count of column-1 '#' lines (no plaintext printed)
  read -r note_chars hash_lines < <(pass show "$rel" | awk 'NR>1{c+=length+1; if($0~/^#/)h++} END{print c+0, h+0}')

  if [ "$hash_lines" -gt 0 ]; then
    log "manual (# comments stripped by rbw): $rel  -> add via Bitwarden web UI"; manual=$((manual + 1)); continue
  fi
  if [ "$note_chars" -gt 7000 ]; then
    log "manual (note ${note_chars} chars > rbw limit): $rel  -> add via Bitwarden web UI"; manual=$((manual + 1)); continue
  fi

  args=(rbw add)
  [ -n "$folder" ] && args+=(--folder "$folder")
  args+=("$name")

  if pass show "$rel" | "${args[@]}" >/dev/null 2>&1; then
    log "added: ${folder:+$folder/}$name"; add=$((add + 1))
  else
    log "fail: $rel"; fail=$((fail + 1))
  fi
done < <(find -L "$STORE" -type f -name '*.gpg')

log "done: $add added, $skip skipped, $manual need manual entry, $fail failed"
