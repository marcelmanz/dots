#!/usr/bin/env bash

# Path to the Cargofile
cargofile="./Cargofile"

# Check if the Cargofile exists
if [[ ! -f "$cargofile" ]]; then
  echo "Error: Cargofile not found at $cargofile"
  exit 1
fi

# Read each line from the Cargofile and install the binary
while IFS= read -r binary; do
  if [[ -n "$binary" ]]; then
    echo "Installing $binary..."
    cargo install "$binary" || echo "Failed to install $binary. Skipping..."
  fi
done < "$cargofile"

