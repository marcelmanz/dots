#!/usr/bin/env bash

upower -i $(upower -e | grep BAT) | grep 'time to empty' | cut -d: -f2 | tr -s ' ' | xargs
