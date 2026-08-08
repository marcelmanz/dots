#!/usr/bin/env bash
# fzf picker over the rbw vault; prints the selected entry's password to stdout

selected=$(rbw ls --fields id,name 2>/dev/null | fzf)
[ -n "$selected" ] && rbw get "${selected%%$'\t'*}"
