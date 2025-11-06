#!/usr/bin/env bash
pamixer "$@" && pamixer --get-volume > $XDG_RUNTIME_DIR/wob-volume.sock
