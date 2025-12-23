#!/usr/bin/env bash

set -euo pipefail

cd ~/notes/ || exit 1

# Use zk's built-in interactive mode to select and edit notes
# Exclude TODO files from the selection
zk edit --interactive --exclude "TODO:*" "$@"

cd - >/dev/null 2>&1
