#!/usr/bin/env bash

package_name=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].name')

cargo build > /dev/null 2>&1
./target/debug/$package_name "$@"
