#!/usr/bin/env bash

# Get the output of sensors command
sensors_output=$(sensors)

# Extract temperature readings using grep and awk
cpu_temp=$(echo "$sensors_output" | grep -i 'CPU:' | awk '{print $2}' | tr -d '+°C')
gpu_temp=$(echo "$sensors_output" | grep -i 'edge:' | awk '{print $2}' | tr -d '+°C')
nvme_temp=$(echo "$sensors_output" | grep -i 'Composite:' | awk '{print $2}' | tr -d '+°C')
acpi_temp=$(echo "$sensors_output" | grep -i 'temp1:' | tail -n 1 | awk '{print $2}' | tr -d '+°C')

# Sum the temperatures
sum=$(echo "$cpu_temp + $gpu_temp + $nvme_temp + $acpi_temp" | bc)

# Calculate the average temperature
count=4
average=$(echo "scale=2; $sum / $count" | bc)

# Print the average temperature
echo $average
