#!/usr/bin/env bash
set -euo pipefail

rev="${1:-}"
if [[ -z "$rev" ]]; then
    echo "usage: workspace <branch|commit|tag>"
    exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "workspace: not inside a git repo"
    exit 1
fi

root="$(git rev-parse --show-toplevel)"
repo_name="$(basename "$root")"
safe_rev="$(echo "$rev" | tr '/: ' '---')"
session="ws-${repo_name}-${safe_rev}"

tmp_base="${TMPDIR:-/tmp}"
ws_dir="$(mktemp -d "${tmp_base}/workspace.${repo_name}.${safe_rev}.XXXXXX")"

cleanup() {
    if git -C "$root" worktree list --porcelain | grep -q "worktree $ws_dir"; then
        git -C "$root" worktree remove --force "$ws_dir" >/dev/null 2>&1 || true
    fi
    rm -rf "$ws_dir" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

git -C "$root" rev-parse --verify "$rev^{commit}" >/dev/null 2>&1

if git -C "$root" show-ref --verify --quiet "refs/heads/$rev"; then
    git -C "$root" worktree add "$ws_dir" "$rev" >/dev/null
else
    git -C "$root" worktree add --detach "$ws_dir" "$rev" >/dev/null
fi

if tmux has-session -t "$session" 2>/dev/null; then
    tmux attach -t "$session"
else
    tmux new-session -s "$session" -c "$ws_dir"
fi
