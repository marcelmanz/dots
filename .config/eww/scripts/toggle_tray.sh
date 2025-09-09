#!/bin/bash

SCREEN=${1:-0}
WINDOW="tray-window${SCREEN}"

if eww close $WINDOW 2>/dev/null; then
    eww update tray${SCREEN}_active=false
else
    eww open $WINDOW 2>/dev/null
    eww update tray${SCREEN}_active=true
fi
