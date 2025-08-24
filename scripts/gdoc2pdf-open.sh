#!/usr/bin/env bash
set -euo pipefail

# requires gcloud, curl, zathura
# to install gcloud: sudo snap install google-cloud-cli --classic
#
# then do gcloud auth login

url="${1:?usage: $0 <google-doc-url> [outfile.pdf]}"
id=$(printf '%s' "$url" | sed -n 's|.*/d/\([^/?#]*\).*|\1|p')
[ -n "$id" ] || {
  echo "could not parse doc id" >&2
  exit 1
}

out="${2:-gdoc-$id-$(date +%Y%m%d-%H%M%S).pdf}"
tmp="$(mktemp)"

get_token() {
  if command -v gcloud >/dev/null 2>&1; then
    if t=$(gcloud auth application-default print-access-token 2>/dev/null); then
      printf '%s' "$t"
      return
    fi
    if t=$(gcloud auth print-access-token 2>/dev/null); then
      printf '%s' "$t"
      return
    fi
  fi
  return 1
}

token="$(get_token)" || {
  echo "no access token; run gcloud auth first" >&2
  exit 1
}

status=$(curl -sS -w '%{http_code}' -H "Authorization: Bearer $token" -o "$tmp" \
  "https://www.googleapis.com/drive/v3/files/$id/export?mimeType=application/pdf&supportsAllDrives=true")

ctype="$(file --mime-type -b "$tmp" || true)"

if [ "$status" != "200" ] || [ "${ctype#application/pdf}" = "$ctype" ]; then
  if grep -q 'ACCESS_TOKEN_SCOPE_INSUFFICIENT' "$tmp" 2>/dev/null; then
    echo "export failed: token missing Drive scope" >&2
    echo "fix: gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/drive.readonly" >&2
  else
    echo "export failed ($status)" >&2
    echo "------ response snippet ------" >&2
    head -c 512 "$tmp" >&2 || true
    echo >&2
  fi
  rm -f "$tmp"
  exit 1
fi

mv "$tmp" "$out"
zathura "$out" >/dev/null 2>&1 &
echo "opened $out"
