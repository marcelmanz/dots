#!/usr/bin/env bash

package_name=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].name')
bin=./target/debug/$package_name

if [ ! -f "$bin" ] || find src -type f -newer "$bin" | read; then
	echo "Running cargo build..."
	cargo build >/dev/null 2>&1
fi

./target/debug/$package_name "$@"
