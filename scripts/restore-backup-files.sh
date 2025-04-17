#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config"
BACKUP_EXTENSION_ARG="$1"

if [ -z "$BACKUP_EXTENSION_ARG" ]; then
  echo "Usage: $0 <backup_extension>"
  echo "Example: $0 .bak"
  exit 1
fi

find "$CONFIG_DIR" -type f -name "*$BACKUP_EXTENSION_ARG" | while read file; do
  
  if [ -z "$file" ]; then
    echo "No files found with extension: $BACKUP_EXTENSION_ARG"
    exit 1
  fi

  new_name="${file%$BACKUP_EXTENSION_ARG}"

  mv "$file" "$new_name"
  echo "Renamed: $file -> $new_name"
done

echo "Completed."
