#!/usr/bin/env bash

module_name="vpn"
default_vpn="WS VPN EU"

active_vpn() {
	nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2 == "vpn" || $2 == "wireguard" { print $1; exit }'
}

print_status() {
	if [ -n "$(active_vpn)" ]; then
		ironbar style add-class "$module_name" connected >/dev/null 2>&1
	else
		ironbar style remove-class "$module_name" connected >/dev/null 2>&1
	fi

	echo "󰖂"
}

toggle() {
	vpn=$(active_vpn)

	if [ -n "$vpn" ]; then
		nmcli connection down "$vpn" >/dev/null && status="$vpn disconnected"
	else
		vpn="$default_vpn"
		nmcli connection up "$vpn" >/dev/null && status="$vpn connected"
	fi

	notify-send -t 1500 -a "VPN" -h string:x-canonical-private-synchronous:vpn "󰖂  ${status:-$vpn failed}"
}

if [ "$1" = "toggle" ]; then
	toggle
	exit
fi

print_status

nmcli monitor | while read -r _; do
	print_status
done
