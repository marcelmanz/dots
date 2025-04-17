#!/usr/bin/env bash

CURL="$@"

TOKEN=$(~/scripts/get-kc-token.sh)

if [ $? -ne 0 ]; then
	echo "Failed to get new token"
	exit 1
fi

NEW_CURL_ARGS=$(echo "$CURL" | sed -E "s/'Bearer [^']*'/'Bearer $TOKEN'/g" | sed -E 's/"Bearer [^"]*"/"Bearer $NEW_TOKEN"/g' | sed -E 's/Bearer [^ ]*/Bearer '"$TOKEN"'/g')

echo $NEW_CURL_ARGS
