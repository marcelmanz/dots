#!/usr/bin/env bash

cd ~/notes/ || exit 1

current_date_todo="TODO:$(date +'%Y-%m-%d').md"

previous_date=$(date -d "yesterday" +'%d-%m-%Y')
previous_date_todo="TODO:$previous_date.md"

if [ ! -f $current_date_todo ]; then
	touch $current_date_todo
	echo "# TODO: $(date +'%d-%m-%Y')" >>$current_date_todo
	echo "" >>$current_date_todo

	if [ -f $previous_date_todo ]; then
		echo "## Yesterday's TODOs" >>$current_date_todo
		echo "[[TODO:$previous_date]]" >>$current_date_todo
		echo "" >>$current_date_todo
	fi

	echo "- [ ] " >>$current_date_todo
fi

nvim $current_date_todo

cd - >/dev/null 2>&1
