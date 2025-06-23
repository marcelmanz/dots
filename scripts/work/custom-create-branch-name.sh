#!/usr/bin/env bash

# Script to generate standardized branch names from TargetProcess URLs
# Example URL: https://ws.tpondemand.com/entity/93051-error-creating-a-new-tenant-with
#
# Branch should be like this:
# feature/delete-unused-settings-components-tp85372-2025-02-05-mmanzanares
# bug/fix-incorrect-tenant-creation-tp93051-2025-02-05-mmanzanares
# [bug][hotfix][feature]/<branch-name>-tp<ticket-number>-<yyyy-mm-dd>-<author>

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -n "$1" ]; then
	tp_input="$1"
else
	echo -e "${BLUE}Enter the TargetProcess URL or ticket number:${NC}"
	read -r tp_input
fi

if [[ "$tp_input" =~ ^[0-9]+$ ]]; then
	ticket_number=$tp_input
	auto_description=""
else
	ticket_number=$(echo "$tp_input" | grep -o '[0-9]\+' | head -1)
	# Extract description from URL after the ticket number
	auto_description=$(echo "$tp_input" | grep -o "${ticket_number}-.*" | sed "s/${ticket_number}-//")
fi

if [ -z "$ticket_number" ]; then
	echo -e "${RED}Error: Could not find valid ticket number${NC}"
	exit 1
fi

# If we have an auto-extracted description, show it and ask for confirmation
if [ -n "$auto_description" ]; then
	echo -e "${BLUE}Found description from URL:${NC} $auto_description"
	echo -e "${BLUE}Do you want to use this description? (Y/n, default: Y):${NC}"
	read -r use_auto_description

	if [[ ! $use_auto_description =~ ^[Yy] && -n "$use_auto_description" ]]; then
		echo -e "${BLUE}Enter a brief description:${NC}"
		read -r description
		auto_description=$(echo "$description" |
			tr '[:upper:]' '[:lower:]' |
			sed -e 's/[^a-zA-Z0-9]/-/g' |
			sed -e 's/--*/-/g' |
			sed -e 's/^-//' -e 's/-$//')
	fi
fi

echo -e "${BLUE}Is this a bug, a hotfix or a feature? (b/h/f):${NC}"
read -r type_answer

case "$type_answer" in
[Bb]*)
	prefix="bug"
	;;
[Ff]*)
	prefix="feature"
	;;
[hH]*)
	prefix="hotfix"
	;;
*)
	echo -e "${RED}Invalid choice. Please use 'b' for bug, 'f' for feature or 'h' for hotfix.${NC}"
	exit 1
	;;
esac

current_date=$(date +%Y-%m-%d)

# git_user=$(git config user.name | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
git_user="mmanzanares" # override this for the company

branch_name="${prefix}/${auto_description}-tp${ticket_number}-${current_date}-${git_user}"
branch_name=$(echo "$branch_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

echo -e "${GREEN}Generated branch name:${NC} $branch_name"

if command -v wl-copy >/dev/null 2>&1; then
	echo "$branch_name" | wl-copy
	echo -e "${GREEN}Branch name copied to clipboard!${NC}"
elif command -v xclip >/dev/null 2>&1; then
	echo "$branch_name" | xclip -selection clipboard
	echo -e "${GREEN}Branch name copied to clipboard!${NC}"
fi

echo -e "${BLUE}Do you want to create and checkout this branch? (Y/n, default: Y):${NC}"
read -r checkout_answer

if [[ $checkout_answer =~ ^[Yy] || -z "$checkout_answer" ]]; then
	if git checkout -b "$branch_name" 2>/dev/null; then
		echo -e "${GREEN}Successfully created and checked out branch: $branch_name${NC}"
	else
		echo -e "${RED}Failed to create branch${NC}"
		exit 1
	fi
fi
