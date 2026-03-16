#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/how"
CACHE_DIR="$STATE_DIR/cache"

# Check if cache directory exists
if [[ ! -d "$CACHE_DIR" ]]; then
	echo "No cache directory found at $CACHE_DIR" >&2
	exit 1
fi

# Check if fzf is available
if ! command -v fzf >/dev/null 2>&1; then
	echo "fzf is required but not installed" >&2
	exit 1
fi

# Function to preview cache content
preview_cache() {
	local hash="$1"
	local cache_file="$CACHE_DIR/$hash"

	if [[ -f "$cache_file" ]]; then
		if command -v bat >/dev/null 2>&1; then
			bat --language markdown --paging never --style plain --color=always --line-range=:20 "$cache_file" 2>/dev/null || cat "$cache_file"
		else
			head -n 20 "$cache_file"
		fi
	else
		echo "Cache file not found"
	fi
}

# Export function for use in fzf preview
export -f preview_cache
export CACHE_DIR

# Create a temporary file to store query-hash mappings
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Iterate through cache files and create entries for fzf
for cache_file in "$CACHE_DIR"/*; do
	[[ -f "$cache_file" ]] || continue

	# Get the hash from filename
	hash=$(basename "$cache_file")

	# Get first few lines of cache file as preview (limit to 3 lines)
	preview=$(head -n3 "$cache_file" | tr '\n' ' ' | cut -c1-100)

	# Get file modification time
	mod_time=$(stat -c %y "$cache_file" 2>/dev/null | cut -d' ' -f1-2 || stat -f %Sm -t "%Y-%m-%d %H:%M" "$cache_file" 2>/dev/null || echo "unknown")

	# Store in temp file: timestamp|hash|preview
	printf '%s|%s|%s\n' "$mod_time" "$hash" "$preview" >>"$temp_file"
done

# Check if we have any cache files
if [[ ! -s "$temp_file" ]]; then
	echo "No cached queries found" >&2
	exit 0
fi

# Sort by timestamp (newest first) and present in fzf
selected=$(sort -r "$temp_file" | cut -d'|' -f2- | fzf \
	--header="Select a cached query (ESC to cancel)" \
	--preview='preview_cache {1}' \
	--delimiter='|' \
	--with-nth=2.. \
	--height=80% \
	--layout=reverse \
	--border)

# Check if user selected something
if [[ -z "$selected" ]]; then
	exit 0
fi

# Extract the hash (first field)
selected_hash=$(echo "$selected" | cut -d'|' -f1)

# Display the cached content
cache_file="$CACHE_DIR/$selected_hash"
if [[ -f "$cache_file" ]]; then
	if command -v bat >/dev/null && [[ -t 1 ]]; then
		bat --language markdown --paging never --style plain <"$cache_file"
	else
		cat "$cache_file"
	fi
else
	echo "Cache file not found: $cache_file" >&2
	exit 1
fi

# Check if fzf is available
if ! command -v fzf >/dev/null 2>&1; then
	echo "fzf is required but not installed" >&2
	exit 1
fi

# Create a temporary file to store query-hash mappings
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Iterate through cache files and create entries for fzf
for cache_file in "$CACHE_DIR"/*; do
	[[ -f "$cache_file" ]] || continue

	# Get the hash from filename
	hash=$(basename "$cache_file")

	# Get first few lines of cache file as preview (limit to 3 lines)
	preview=$(head -n3 "$cache_file" | tr '\n' ' ' | cut -c1-100)

	# Get file modification time
	mod_time=$(stat -c %y "$cache_file" 2>/dev/null | cut -d' ' -f1-2 || stat -f %Sm -t "%Y-%m-%d %H:%M" "$cache_file" 2>/dev/null || echo "unknown")

	# Store in temp file: timestamp|hash|preview
	printf '%s|%s|%s\n' "$mod_time" "$hash" "$preview" >>"$temp_file"
done

# Check if we have any cache files
if [[ ! -s "$temp_file" ]]; then
	echo "No cached queries found" >&2
	exit 0
fi

# Sort by timestamp (newest first) and present in fzf
selected=$(sort -r "$temp_file" | cut -d'|' -f2- | fzf \
	--header="Select a cached query (ESC to cancel)" \
	--preview="cache_file=\"$CACHE_DIR/{1}\"; if [[ -f \"\$cache_file\" ]]; then if command -v bat >/dev/null 2>&1; then bat --language markdown --paging never --style plain \"\$cache_file\"; else cat \"\$cache_file\"; fi; fi" \
	--delimiter='|' \
	--with-nth=2.. \
	--height=80% \
	--layout=reverse \
	--border)

# Check if user selected something
if [[ -z "$selected" ]]; then
	exit 0
fi

# Extract the hash (first field)
selected_hash=$(echo "$selected" | cut -d'|' -f1)

# Display the cached content
cache_file="$CACHE_DIR/$selected_hash"
if [[ -f "$cache_file" ]]; then
	if command -v bat >/dev/null && [[ -t 1 ]]; then
		bat --language markdown --paging never --style plain <"$cache_file"
	else
		cat "$cache_file"
	fi
else
	echo "Cache file not found: $cache_file" >&2
	exit 1
fi

# Check if fzf is available
if ! command -v fzf >/dev/null 2>&1; then
	echo "fzf is required but not installed" >&2
	exit 1
fi

# Create a temporary file to store query-hash mappings
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Iterate through cache files and try to find query mappings
# Since we don't have direct mapping from hash to query, we'll show file timestamps
for cache_file in "$CACHE_DIR"/*; do
	[[ -f "$cache_file" ]] || continue

	# Get the hash from filename
	hash=$(basename "$cache_file")

	# Get first line of cache file as preview
	first_line=$(head -n1 "$cache_file" | cut -c1-50)

	# Get file modification time
	mod_time=$(stat -c %y "$cache_file" 2>/dev/null | cut -d' ' -f1-2 || stat -f %Sm -t "%Y-%m-%d %H:%M" "$cache_file" 2>/dev/null || echo "unknown")

	# Store in temp file: timestamp|hash|preview
	printf '%s|%s|%s\n' "$mod_time" "$hash" "$first_line" >>"$temp_file"
done

# Check if we have any cache files
if [[ ! -s "$temp_file" ]]; then
	echo "No cached queries found" >&2
	exit 0
fi

# Sort by timestamp (newest first) and present in fzf
selected=$(sort -r "$temp_file" | cut -d'|' -f2- | fzf \
	--header="Select a cached query (ESC to cancel)" \
	--preview="echo 'Hash: {1}\nPreview: {2}'" \
	--delimiter='|' \
	--with-nth=2.. \
	--height=80% \
	--layout=reverse \
	--border)

# Check if user selected something
if [[ -z "$selected" ]]; then
	exit 0
fi

# Extract the hash (first field)
selected_hash=$(echo "$selected" | cut -d'|' -f1)

# Display the cached content
cache_file="$CACHE_DIR/$selected_hash"
if [[ -f "$cache_file" ]]; then
	if command -v bat >/dev/null && [[ -t 1 ]]; then
		bat --language markdown --paging never --style plain <"$cache_file"
	else
		cat "$cache_file"
	fi
else
	echo "Cache file not found: $cache_file" >&2
	exit 1
fi
