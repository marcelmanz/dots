#!/usr/bin/env bash

TERM_PACKAGES=~/.config/nix/home/terminal-packages.nix
GUI_CONFIG=~/.config/nix/home/gui.nix

parse_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		gui)
			TARGET="gui"
			shift
			;;
		term)
			TARGET="term"
			shift
			;;
		*)
			if [[ -z "$PACKAGE" ]]; then
				PACKAGE="$1"
				shift
			else
				echo "Unknown argument: $1"
				exit 1
			fi
			;;
		esac
	done

	if [[ -z "$TARGET" || -z "$PACKAGE" ]]; then
		echo "Usage: nixpack [term|gui] <package>"
		exit 1
	fi
}

check_package_exists() {
	RESULTS=$(nix-search "$PACKAGE" | grep -v "Searching")
	if [[ -z "$RESULTS" ]]; then
		return 1
	fi
	echo "Found the following results for '$PACKAGE':"
	echo "$RESULTS" | awk '{print "  " $0}'
	echo
	BEST_MATCH=$(echo "$RESULTS" | head -n 1 | awk '{print $1}')
	echo "→ Closest match: $BEST_MATCH"
	echo
	read -r -p "Use '$BEST_MATCH'? [Y/n] " CONFIRM
	CONFIRM=${CONFIRM:-Y}
	if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
		PACKAGE="$BEST_MATCH"
		return 0
	else
		echo "Cancelled."
		exit 0
	fi
}

add_to_term() {
	if grep -qE "^\s*${PACKAGE}\s*$" "$TERM_PACKAGES"; then
		echo "$PACKAGE already present in terminal-packages.nix"
		return
	fi

	sed -i "/^\s*\]/i\  ${PACKAGE}" "$TERM_PACKAGES"
	echo "Added ${PACKAGE} to terminal-packages.nix"
}

add_to_gui() {
	if grep -qE "^\s*${PACKAGE}\s*$" "$GUI_CONFIG"; then
		echo "$PACKAGE already present in gui.nix"
		return
	fi

	sed -i "/^\s*\]/i\    ${PACKAGE}" "$GUI_CONFIG"
	echo "Added ${PACKAGE} to gui.nix"
}

rebuild_system() {
	echo "Running nixos-rebuild switch..."
	sudo nixos-rebuild switch --flake ~/.config/nix#nixos
}

parse_args "$@"

if ! check_package_exists; then
	echo "Package '$PACKAGE' not found in nixpkgs"
	exit 1
fi

case "$TARGET" in
term) add_to_term ;;
gui) add_to_gui ;;
esac

rebuild_system
