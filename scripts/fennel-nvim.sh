#!/bin/bash
# Script to run Neovim with Fennel kickstart configuration

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set the NVIM_APPNAME to use this config as an alternative
export NVIM_APPNAME="kickstart-fennel"

# Create config directory if it doesn't exist
CONFIG_DIR="$HOME/.config/$NVIM_APPNAME"
if [ ! -d "$CONFIG_DIR" ]; then
	echo "Creating config directory: $CONFIG_DIR"
	mkdir -p "$CONFIG_DIR"

	# Copy our configuration
	cp -r "$SCRIPT_DIR"/* "$CONFIG_DIR/" 2>/dev/null

	# Remove this script from the config directory
	rm -f "$CONFIG_DIR/nvim-fennel"

	echo "Fennel kickstart config installed to $CONFIG_DIR"
fi

# Launch Neovim with the Fennel configuration
echo "Starting Neovim with Fennel kickstart configuration..."
nvim "$@"
