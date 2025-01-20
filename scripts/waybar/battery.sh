#!/usr/bin/env bash

format_time() {
    echo "$1" | cut -d: -f2 | tr -s ' ' | sed 's/ hours/h/' | sed 's/ minutes/m/' | sed 's/ seconds/s/' | xargs
}

BATTERY_INFO="$(upower -i $(upower -e | grep BAT))"
BATTERY_PERCENTAGE="$(echo "$BATTERY_INFO" | grep 'percentage' | awk '{print $2}')"
BATTERY_STATE="$(echo "$BATTERY_INFO" | grep 'state' | awk '{print $2}')"

PERCENTAGE_DISPLAY="󰁹 $BATTERY_PERCENTAGE"

if [[ "$BATTERY_STATE" == "charging" ]]; then
	TIME_VALUE="$(format_time "$(echo "$BATTERY_INFO" | grep 'time to full')")"
	ICON="󰂄"
else
	TIME_VALUE="$(format_time "$(echo "$BATTERY_INFO" | grep 'time to empty')")"
	ICON="󰂃"
fi

TIME_DISPLAY="${TIME_VALUE:+$ICON $TIME_VALUE}"

echo "$PERCENTAGE_DISPLAY  $TIME_DISPLAY"
