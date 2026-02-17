#!/usr/bin/env bash
set -euo pipefail

PROFILE_DIR=$(awk -F= '
  $1=="Default" && $2==1 {d=1}
  d && $1=="Path" {print $2; exit}
' ~/.mozilla/firefox/profiles.ini)

PROFILE="$HOME/.mozilla/firefox/$PROFILE_DIR"

CONTAINER_ID=$(jq -r '
  .identities[] | select(.name=="Work") | .userContextId
' "$PROFILE/containers.json")

curl -sf http://localhost:9222/json/list |
    jq -e ".[] | select(.browserContextId==\"firefox-container-$CONTAINER_ID\")" \
        >/dev/null
