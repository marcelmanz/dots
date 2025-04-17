#!/usr/bin/env bash

# NAME: suspendtime
# PATH: $HOME/askubuntu/
# DESC: For: https://askubuntu.com/questions/321855/how-to-get-real-uptime
# DATE: November 6, 2019.

# NOTE: Calculate suspend time from systemd's journalctl

# UPDT: 2019-11-07 Fine-tune removing 0 Units in DaysMinutesStr
# UPDT: 2020-05-05 works with Ubuntu 20.04 but has problem with changing monthes

# Duplicate DaysMinutes from ~/.bashrc for Ask Ubuntu
DaysMinutes() {

	local d h m s
	((d = ${1} / 86400))
	((h = (${1} % 86400) / 3600))
	((m = (${1} % 3600) / 60))
	((s = ${1} % 60))
	DaysMinutesStr="$d days, $h hours, $m minutes, $s seconds"

	# Convert 1's to singular
	[[ ${DaysMinutesStr:0:2} = "1 " ]] &&
		DaysMinutesStr="${DaysMinutesStr/days/day}"
	DaysMinutesStr="${DaysMinutesStr/ 1 hours/ 1 hour}"
	DaysMinutesStr="${DaysMinutesStr/ 1 minutes/ 1 minute}"
	DaysMinutesStr="${DaysMinutesStr/ 1 seconds/ 1 second}"

	# Suppress zero strings
	[[ ${DaysMinutesStr:0:1} = "0" ]] &&
		DaysMinutesStr="${DaysMinutesStr/0 days, / }"
	DaysMinutesStr="${DaysMinutesStr/ 0 hours, / }"
	DaysMinutesStr="${DaysMinutesStr/ 0 minutes, / }"
	DaysMinutesStr="${DaysMinutesStr/, 0 seconds/}"
} # DaysMinutes

# Build array of suspend cycles from Systemd
IFS=$'\n' Arr=($(journalctl -b-0 | grep -E 'PM: suspend' | cut -c5-15))

[[ ${#Arr[@]} -gt 0 ]] && upper=$((${#Arr[@]} - 1))
SuspentCount=0
[[ $upper -gt 0 ]] && for ((i = 0; i < upper; i = i + 2)); do
	((SuspendCount++))
	Time=$(($(date +%s -d "2020-01-${Arr[i + 1]}") - $(date +%s -d "2020-01-${Arr[i]}")))
	SuspendTime=$((SuspendTime + Time))
	printf "%s to %s lasting %'d seconds\n" "${Arr[i]}" "${Arr[i + 1]}" "$Time"
done

echo
LinuxTime=$(($(date +%s -d "Now") - $(date +%s -d "$(uptime -s)")))
DaysMinutes "$LinuxTime"
printf "Linux uptime \t%'d seconds (%s)\n" "$LinuxTime" "$DaysMinutesStr"
if [ $SuspendCount ] >0; then
	DaysMinutes "$SuspendTime"
	printf "%sx Suspend \t%'d seconds (%s)\n" "$SuspendCount" "$SuspendTime" "$DaysMinutesStr"
fi
RealTime=$((LinuxTime - SuspendTime))
DaysMinutes "$RealTime"
printf "Real uptime \t%'d seconds (%s)\n" "$RealTime" "$DaysMinutesStr"
