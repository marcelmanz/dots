#!/usr/bin/env bash

selected=$(lsblk -l | awk '{print $1}') 

to_print=$(echo $selected | tail -n +2 | fzf)




