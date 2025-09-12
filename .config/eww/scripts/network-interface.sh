#!/bin/bash
# Get the active network interface (excluding loopback and docker interfaces)
interface=$(ip route show default | awk '{print $5}' | head -1)
# Fallback to any non-loopback interface if no default route
if [[ -z "$interface" ]]; then
    interface=$(ip addr show | grep -E "^[0-9]+: " | awk '{print $2}' | sed 's/://' | grep -v -E "^(lo|docker|br-|veth)" | head -1)
fi
echo "$interface"