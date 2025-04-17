#!/usr/bin/env bash

# Default values
TARGET_PATH=""
FILE_PATH=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            TARGET_PATH="$2"
            shift 2
            ;;
        --file)
            FILE_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 --target <target_path> --file <file_path>"
            exit 1
            ;;
    esac
done

if [[ -z "$TARGET_PATH" ]] || [[ -z "$FILE_PATH" ]]; then
    echo "Error: Both --target and --file parameters are required"
    echo "Usage: $0 --target <target_path> --file <file_path>"
    exit 1
fi

target_dirs=$(ls $TARGET_PATH -d */)

for dir in $target_dirs; do
    cp $FILE_PATH $dir
    echo "Copied $FILE_PATH to $dir"
done

