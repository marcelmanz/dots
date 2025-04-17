#!/bin/env bash

ENV=${1:-dev}
ENV_FILE="ENV/local.env" # we could load this dynamically if we define a convention for the env file
BACKUP_FILE="backup_$(date +'%Y%m%d%H%M%S').env"

if [ ! -f "$ENV_FILE" ]; then
	echo "File $ENV_FILE doesn't exist"
	exit 1
fi

# for now always ask for the password
eval "$(op signin)"

service_name=$(basename "$(git rev-parse --show-toplevel)")
item_name="$service_name.$ENV.local.env"

if ! op item list --vault "ENV" | grep -q "$item_name"; then
	echo "File doesn't exist in the vault"
	exit 1
fi

op read "op://ENV/$item_name/notesPlain" >"$BACKUP_FILE"
echo "Backup saved to $BACKUP_FILE"

filter_env() {
	local input_file=$1
	local output_file=$2
	if [ -f .openvignore ]; then
		ignore_pattern=$(grep -vE '^\s*#' .openvignore | grep -vE '^\s*$' | sed 's/^/^/' | tr '\n' '|' | sed 's/|$//')
		if [ -n "$ignore_pattern" ]; then
			grep -vE "$ignore_pattern" "$input_file" >"$output_file"
		else
			cp "$input_file" "$output_file"
		fi
	else
		cp "$input_file" "$output_file"
	fi
}

REMOTE_ENV_TEMP=$(mktemp)
LOCAL_ENV_TEMP=$(mktemp)

op read "op://ENV/$item_name/notesPlain" >"$REMOTE_ENV_TEMP"
filter_env "$REMOTE_ENV_TEMP" "${REMOTE_ENV_TEMP}_filtered"
filter_env "$ENV_FILE" "${LOCAL_ENV_TEMP}_filtered"

CURRENT_DIFF_EXTERNAL=$(git config --global --get diff.external || echo "")
CURRENT_DIFF_TOOL=$(git config --global --get diff.tool || echo "")

git config --global --unset diff.external
git config --global --unset diff.tool

if ! git diff --no-index "${LOCAL_ENV_TEMP}_filtered" "${REMOTE_ENV_TEMP}_filtered" ; then
	echo "The remote environment file is NOT in sync with the local file."
	echo "Do you want to update the vault file? [y/N]"
	read -r answer
	if [ "$answer" == "y" ]; then
		op item edit "op://ENV/$item_name" notesPlain <"$ENV_FILE"
		echo "Vault file updated."
	else
		echo "Vault file not updated."
		echo "Remember to update the vault file manually."
	fi
else
	echo "The remote environment file is in sync with the local file."
fi

if [ -n "$CURRENT_DIFF_EXTERNAL" ]; then
    git config --global diff.external "$CURRENT_DIFF_EXTERNAL"
fi
if [ -n "$CURRENT_DIFF_TOOL" ]; then
    git config --global diff.tool "$CURRENT_DIFF_TOOL"
fi

rm -f "$REMOTE_ENV_TEMP" "${REMOTE_ENV_TEMP}_filtered" "${LOCAL_ENV_TEMP}_filtered"
