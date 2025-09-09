#!/bin/bash

pkill -f "eww open" 2>/dev/null
pkill -f "eww daemon" 2>/dev/null
eww kill 2>/dev/null
eww open bar0 &
eww open bar1 &

