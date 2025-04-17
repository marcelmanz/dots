#!/usr/bin/env bash

# colors
GREEN='\033[1;32m' # bold
BLUE='\033[0;34m'
RED='\033[1;31m'   # bold
NC='\033[0m'       # No Color

export TARGET_PATH=""        # path containing multiple dirs/repos
export ACTION_SCRIPT_PATH="" # script to execute in each dir
export COMMAND=""            # command to execute in each dir
export IGNORE_DIRS=""        # comma-separated list of dirs to ignore

while [[ $# -gt 0 ]]; do
	case $1 in
	--target)
		TARGET_PATH="$2"
		shift 2
		;;
	--script)
		ACTION_SCRIPT_PATH="$2"
		shift 2
		;;
	--cmd)
		COMMAND="$2"
		shift 2
		;;
	--ignore)
		IGNORE_DIRS="$2"
		shift 2
		;;
	*)
		echo "Unknown parameter: $1"
		echo "Usage: $0 --target <target_path> (--script <action_script> | --cmd <command>) [--ignore dir1,dir2,...]"
		exit 1
		;;
	esac
done

if [[ -n "$ACTION_SCRIPT_PATH" ]] && [[ -n "$COMMAND" ]]; then
	echo -e "${RED}Error: Cannot use both --script and --cmd parameters${NC}"
	echo "Usage: $0 --target <target_path> (--script <action_script> | --cmd <command>)"
	exit 1
fi

# check if script exists and is executable
if [[ -n "$ACTION_SCRIPT_PATH" ]]; then
	ABSOLUTE_SCRIPT_PATH=$(realpath "$ACTION_SCRIPT_PATH" 2>/dev/null)
	if [[ ! -f "$ABSOLUTE_SCRIPT_PATH" ]]; then
		echo -e "${RED}Error: Script '$ACTION_SCRIPT_PATH' not found${NC}"
		exit 1
	elif [[ ! -x "$ABSOLUTE_SCRIPT_PATH" ]]; then
		echo -e "${RED}Error: Script '$ACTION_SCRIPT_PATH' is not executable${NC}"
		exit 1
	fi
fi

if [[ -n "$COMMAND" ]]; then
	cmd_name=$(echo "$COMMAND" | awk '{print $1}')
	if ! command -v "$cmd_name" &>/dev/null; then
		echo -e "${RED}Error: Command '$cmd_name' not found${NC}"
		exit 1
	fi
fi

number_of_dirs=$(ls -d "$TARGET_PATH"/*/ | wc -l)

IFS=',' read -ra IGNORE_ARRAY <<< "$IGNORE_DIRS"

for dir in "$TARGET_PATH"/*/; do
	dir_name=$(basename "$dir")
	
	should_ignore=false
	for ignore_dir in "${IGNORE_ARRAY[@]}"; do
		if [[ "$dir_name" == "$ignore_dir" ]]; then
			echo -e "${BLUE}Skipping ignored directory:${NC} ${GREEN}$dir_name${NC}"
			should_ignore=true
			break
		fi
	done
	
	if [[ "$should_ignore" == true ]]; then
		continue
	fi
	(
		cd "$dir" || {
			echo -e "${RED}Failed to cd into $dir${NC}"
			exit 1
		}

		printf '\n'
		if [[ -n "$COMMAND" ]]; then
			echo -e "${BLUE}Executing${NC} $COMMAND ${BLUE}command in${NC} ${GREEN}$dir_name${NC}"
			eval "$COMMAND"
			exit 1
		fi

		echo -e "${BLUE}Executing${NC} $ACTION_SCRIPT_PATH ${BLUE}script in${NC} ${GREEN}$dir_name${NC}"
		bash "$ABSOLUTE_SCRIPT_PATH"
		printf '\n'
	)
done

echo "All $number_of_dirs directories in $TARGET_PATH have been processed successfully"
