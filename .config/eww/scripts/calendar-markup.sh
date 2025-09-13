#!/usr/bin/env bash

# Get today's date
today=$(date +%d)

# Get calendar output and process it
cal | sed "s/\b${today}\b/<span color=\"#e6c446\" weight=\"bold\">${today}<\/span>/g"
carl --year-progress | sed 's/\x1b\[[0-9;]*m//g' | sed -E 's/([0-9]+\.[0-9]+%)/<span color="#e6c446" weight="bold">\1<\/span>/g; s/([0-9]+) left/<span color="#ff6b6b" weight="bold">\1<\/span> left/g'
