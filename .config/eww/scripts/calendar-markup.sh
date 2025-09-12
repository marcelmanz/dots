#!/usr/bin/env bash

# Get today's date
today=$(date +%d)

# Get calendar output and process it
cal | sed "s/\b${today}\b/<span color=\"#e6c446\" weight=\"bold\">${today}<\/span>/g"
carl --year-progress | sed 's/\x1b\[[0-9;]*m//g'
