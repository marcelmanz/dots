#!/usr/bin/env bash

# Check if workspace name parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <workspace_name>"
    echo "Example: $0 'My Workspace'"
    exit 1
fi

# Get the workspace name from the first parameter
WORKSPACE_NAME="$1"

# Get the current active workspace ID using grep and sed
ACTIVE_WORKSPACE=$(hyprctl activeworkspace -j | grep -o '"id": *[0-9]*' | sed 's/"id": *//')

if [ -z "$ACTIVE_WORKSPACE" ]; then
    echo "Error: Could not determine active workspace"
    exit 1
fi

# Prepend the workspace ID to the name
FULL_WORKSPACE_NAME="$ACTIVE_WORKSPACE:$WORKSPACE_NAME"

# Set the workspace name using hyprctl dispatch
hyprctl dispatch renameworkspace "$ACTIVE_WORKSPACE" "$FULL_WORKSPACE_NAME"

# Check if the command succeeded
if [ $? -eq 0 ]; then
    echo "Workspace $ACTIVE_WORKSPACE renamed to: $FULL_WORKSPACE_NAME"
else
    echo "Error: Failed to rename workspace"
    exit 1
fi
