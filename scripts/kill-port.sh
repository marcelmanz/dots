#!/usr/bin/env bash

port=$1

if [ -z $port ]; then
	echo "Usage: kill-port <port>"
	exit 1
fi

lsof -i tcp:${port} | awk 'NR!=1 {print $2}' | xargs kill 2> /dev/null

if [ $? -ne 0 ]; then
	echo "Failed to kill port ${port}"
	exit 1
fi

echo "Port ${port} has been killed"
