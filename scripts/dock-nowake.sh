#!/bin/sh
# disables dock wake sources only; lid and power button still wake the machine
[ "$1" = pre ] || exit 0

for dev in 0000:00:14.0 0000:00:0d.0 0000:00:0d.3 0000:00:07.0 0000:00:1f.6; do
	echo disabled >"/sys/bus/pci/devices/$dev/power/wakeup" 2>/dev/null
done
