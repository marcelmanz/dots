#!/usr/bin/env bash
# Generate qBittorrent WebUI salt + PBKDF2 hash for a new password.
# (PBKDF2-HMAC-SHA512, 100k iterations, 16-byte salt, base64 — same as qBittorrent.conf)
# usage: qbit-pass.sh 'newpassword'
set -euo pipefail
[[ $# -eq 1 ]] || { echo "usage: $0 <new-password>" >&2; exit 1; }
python3 - "$1" <<'PY'
import sys, os, hashlib, base64
salt = os.urandom(16)
h = hashlib.pbkdf2_hmac("sha512", sys.argv[1].encode(), salt, 100000, 64)
s, hs = base64.b64encode(salt).decode(), base64.b64encode(h).decode()
print(f"qbit_password_salt: {s}")
print(f"qbit_password_hash: {hs}")
print(f'conf line:          WebUI\\Password_PBKDF2="@ByteArray({s}:{hs})"')
PY
