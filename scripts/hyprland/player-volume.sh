#!/usr/bin/env bash

case "$1" in
	up) step="+5%" ;;
	down) step="-5%" ;;
	*) echo "usage: $0 up|down" >&2; exit 1 ;;
esac

instance=$(playerctl metadata --format '{{playerInstance}}') || exit 1
player_pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus \
	GetConnectionUnixProcessID s "org.mpris.MediaPlayer2.$instance" | awk '{print $2}')
[ -n "$player_pid" ] || exit 1

descends_from_player() {
	local pid=$1
	while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
		[ "$pid" = "$player_pid" ] && return 0
		pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
	done
	return 1
}

pactl -f json list sink-inputs | jaq -r '.[] | "\(.index) \(.properties."application.process.id")"' |
	while read -r index pid; do
		if descends_from_player "$pid"; then
			pactl set-sink-input-volume "$index" "$step"
			pactl -f json list sink-inputs | jaq -r ".[] | select(.index == $index) | .volume | to_entries[0].value.value_percent" |
				tr -d '%' > "$XDG_RUNTIME_DIR/wob-volume.sock"
		fi
	done
