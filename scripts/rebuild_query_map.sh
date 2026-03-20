#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/how"
CACHE_DIR="$STATE_DIR/cache"
QUERY_MAP_FILE="$STATE_DIR/query_map"

# Create the query map file if it doesn't exist
touch "$QUERY_MAP_FILE"

# For each cache file, create a mapping using the first line as the "query"
for cache_file in "$CACHE_DIR"/*; do
    if [[ -f "$cache_file" ]]; then
        filename=$(basename "$cache_file")
        # Check if this hash is already in the query map
        if ! grep -q "^$filename|" "$QUERY_MAP_FILE" 2>/dev/null; then
            # Get first line and clean it up a bit to use as a query
            first_line=$(head -n1 "$cache_file" | sed 's/^#\+ //' | cut -c1-100)
            # If first line is empty or too short, use a generic description
            if [[ ${#first_line} -lt 5 ]]; then
                first_line="Cached query response"
            fi
            echo "$filename|$first_line" >> "$QUERY_MAP_FILE"
        fi
    fi
done

# Remove duplicates and sort
sort -u "$QUERY_MAP_FILE" -o "$QUERY_MAP_FILE"

echo "Query map rebuilt with $(wc -l < "$QUERY_MAP_FILE") entries"
