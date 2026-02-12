#!/usr/bin/env bash

set -e

OUTPUT_DIR="diagrams"

mkdir -p "$OUTPUT_DIR"

find . -type f -name "*.mmd" | while read -r file; do
    relative_path="${file#./}"
    output_path="$OUTPUT_DIR/${relative_path%.mmd}.svg"

    mkdir -p "$(dirname "$output_path")"

    mmdc -i "$file" -o "$output_path"
done
