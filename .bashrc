# shellcheck disable=2148

shopt -s expand_aliases

export GIT_PROMPT=true
export KUBE_PROMPT=true
export NIX_PROMPT=true
export VI_MODE_PROMPT=true
export GPG_PROGRAM=/usr/bin/gpg
export OPENCODE_MODELS_PATH="/home/$USER/clones/forks/models.dev/packages/web/dist/_api.json"
export SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt

source ~/.bash_aliases
unset _POST_PROMPT_DONE

# nnn plugins
export NNN_PLUG='m:mediainfo'

if [[ $- == *i* ]] && [[ -t 0 ]]; then
	source ~/clones/forks/xelabash/xela.bash
fi

gpsup() {
	local branch
	branch=$(git symbolic-ref --short HEAD 2>/dev/null)
	git push --set-upstream origin "$branch"
}

mmview() {
	[ -z "$1" ] && {
		echo "usage: mmview <file.md>"
		return 1
	}
	local out
	out=$(mktemp -d)
	nix shell nixpkgs#mermaid-cli --command mmdc -i "$1" -o "$out/out.md" >/dev/null || return 1
	{
		printf '<!doctype html><meta charset=utf-8><title>%s</title>' "$1"
		printf '<style>'
		printf 'body{margin:0;background:#111}'
		printf 'section{min-height:100vh;display:flex;align-items:center;justify-content:center;overflow:auto}'
		printf 'img{max-height:100vh;max-width:100vw;background:#fff;padding:1em;box-sizing:border-box;cursor:zoom-in}'
		printf 'img.z{max-height:none;max-width:none;cursor:zoom-out}'
		printf '</style>'
		for f in "$out"/out-*.svg; do
			[ -e "$f" ] && printf '<section><img src="%s" onclick="this.classList.toggle(%c%c%c)"></section>' "$f" 39 z 39
		done
	} >"$out/index.html"
	brave-origin "$out/index.html"
}

sleep_in() {
	local minutes="$1"
	local seconds=$((minutes * 60))

	while [ "$seconds" -gt 0 ]; do
		printf "\rSuspending in %02d:%02d" $((seconds / 60)) $((seconds % 60))
		sleep 1
		seconds=$((seconds - 1))
	done

	echo
	systemctl suspend
}

refresh_techno_playlist() {
	password="$(pass show slskd/account | head -n1)"

	sldl \
		--input "https://www.youtube.com/watch?v=QAyrU6hhVRc&list=PLHa2a9cVibtnn69H5nJ-hMLGmm3t6lz1z&pp=sAgC" \
		--user marcelarie \
		--password "${password}" \
		--pref-format=flac,wav,mp3 \
		--reverse \
		--path="${HOME}/techno-electronica/"
}

# nsh: run package in temporary nix shell
# Usage: nsh [-u|--unstable] [-f|--flake <ref>] <pkg> [args...]
# Options: -u/--unstable (use nixpkgs unstable), -f/--flake (custom flake ref)
nsh() {
	local flake="github:nixos/nixpkgs/nixos-25.11"
	local unstable_flag=0
	local custom_flake=0

	# Parse flags
	while [[ "$1" == -* ]]; do
		case "$1" in
		-u | --unstable)
			if [ $unstable_flag -eq 1 ] || [ $custom_flake -eq 1 ]; then
				echo "Error: cannot use -u/--unstable with -f/--flake" >&2
				return 1
			fi
			flake="github:nixos/nixpkgs/nixos-unstable"
			unstable_flag=1
			shift
			;;
		-f | --flake)
			if [ $unstable_flag -eq 1 ] || [ $custom_flake -eq 1 ]; then
				echo "Error: cannot use -f/--flake with -u/--unstable" >&2
				return 1
			fi
			flake="$2"
			custom_flake=1
			shift 2
			;;
		*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		esac
	done

	local pkg="$1"
	shift

	if [ $# -gt 0 ]; then
		nix shell "${flake}#${pkg}" --command "$pkg" "$@"
	else
		nix shell "${flake}#${pkg}"
	fi
}

hex() {
	# Normalize input: lowercase and remove optional '#'
	hex=$(echo "${1#"#"}" | tr '[:upper:]' '[:lower:]')
	format=""

	# Detect hex format and extract channels
	case ${#hex} in
	3)
		format="RGB"
		r=${hex:0:1}${hex:0:1}
		g=${hex:1:1}${hex:1:1}
		b=${hex:2:1}${hex:2:1}
		;;
	4)
		format="RGBA"
		r=${hex:0:1}${hex:0:1}
		g=${hex:1:1}${hex:1:1}
		b=${hex:2:1}${hex:2:1}
		;;
	6)
		format="RRGGBB"
		r=${hex:0:2}
		g=${hex:2:2}
		b=${hex:4:2}
		;;
	8)
		format="RRGGBBAA"
		r=${hex:0:2}
		g=${hex:2:2}
		b=${hex:4:2}
		;;
	*)
		echo "Invalid color: $1" >&2
		return 1
		;;
	esac

	# Print a colored block, format type, and original input
	printf "\e[48;2;%d;%d;%dm  \e[0m %-10s %s\n" $((16#$r)) $((16#$g)) $((16#$b)) "[$format]" "$1"
}

export -f hex

se() {
	local user=$1
	local env="mlab"
	local timeout=2

	if ssh -q -o ConnectTimeout=$timeout -o BatchMode=yes root@mlab-local exit 2>/dev/null; then
		env="mlab-local"
	fi

	~/scripts/tmux-se.sh "$user" "$env" "${user}_mlab"
}

fhex() {
	# Requires: fzf, curl, jq, and the 'hex' function
	for cmd in fzf curl jq; do
		command -v "$cmd" >/dev/null 2>&1 || {
			echo "$cmd not found" >&2
			return 1
		}
	done
	declare -f hex >/dev/null 2>&1 || {
		echo "hex() not defined" >&2
		return 1
	}

	# Cache file
	cache="${XDG_CACHE_HOME:-$HOME/.cache}/fhex_colors.json"
	mkdir -p "$(dirname "$cache")"

	# Fetch color list if cache missing or older than 7 days
	if [ ! -f "$cache" ] || [ $(($(date +%s) - $(stat -c %Y "$cache"))) -gt 604800 ]; then
		echo "Fetching color list..."
		curl -fsSL "https://api.color.pizza/v1/?list=bestOf" -o "$cache" || {
			echo "Failed to fetch color list" >&2
			return 1
		}
	fi

	# Parse JSON → "name<TAB>#hex"
	tmp=$(mktemp)
	jq -r '.colors[] | "\(.name)\t\(.hex)"' "$cache" >"$tmp" || {
		echo "Failed to parse color list" >&2
		rm -f "$tmp"
		return 1
	}

	# fzf picker with preview using hex
	choice=$(fzf --ansi --preview-window=up:1:wrap \
		--preview 'hex {2}' \
		--delimiter='\t' \
		--with-nth=1 \
		<"$tmp")

	[ -n "$choice" ] && hex "$(echo "$choice" | cut -f2)"
	rm -f "$tmp"
}

if [[ $- == *i* ]]; then
	set -o vi

	if command -v carapace >/dev/null 2>&1; then
		source <(carapace _carapace bash)
	fi
fi

__post_first_prompt_init() {
	if [[ -n "$_POST_PROMPT_DONE" ]]; then return; fi
	_POST_PROMPT_DONE=1

	command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
	command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash --disable-up-arrow)"
	command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
	[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh

	PROMPT_COMMAND="${PROMPT_COMMAND//__post_first_prompt_init;/}"
	PROMPT_COMMAND="${PROMPT_COMMAND//__post_first_prompt_init/}"
	PROMPT_COMMAND="${PROMPT_COMMAND//;;/;}"
}

if [[ $- == *i* ]] && [[ -t 0 ]]; then
	if [[ -n "$TMUX" ]]; then
		__post_first_prompt_init
	else
		PROMPT_COMMAND="__post_first_prompt_init;${PROMPT_COMMAND}"
	fi
fi

vpn_connect() {
	local vpn_name
	vpn_name="$(nmcli connection show | grep -i vpn | fzf --prompt="Select VPN to connect: " --height=10 | awk '{print $1}')"

	if [ -n "$vpn_name" ]; then
		echo "Connecting to $vpn_name..."
		nmcli connection up "$vpn_name"
	else
		echo "No VPN selected"
	fi
}

vpn_disconnect() {
	local vpn_name
	vpn_name="$(nmcli connection show --active | grep -i vpn | fzf --prompt="Select VPN to disconnect: " --height=10 | awk '{print $1}')"

	if [ -n "$vpn_name" ]; then
		echo "Disconnecting $vpn_name..."
		nmcli connection down "$vpn_name"
	else
		echo "No VPN selected"
	fi
}

vpn() {
	local action
	if [ -z "$1" ]; then
		action=$(printf "connect\ndisconnect" | fzf --prompt="VPN action: " --height=5)
	else
		action=$1
	fi

	case "$action" in
	connect)
		vpn_connect
		;;
	disconnect)
		vpn_disconnect
		;;
	*)
		echo "Usage: vpn {connect|disconnect}"
		;;
	esac
}

# Use bash-completion, if available
# [[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] &&
# 	. /usr/share/bash-completion/bash_completion

# Start gpg-agent if not already running
GPG_AGENT_INFO=$(gpgconf --list-dirs agent-socket)
GPG_TTY=$(tty)
export GPG_AGENT_INFO GPG_TTY
SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-$(gpgconf --list-dirs agent-ssh-socket)}
export SSH_AUTH_SOCK

# source "$HOME/.rye/env"
# source rund bash
# eval "$(starship init bash)"

# ENV. VARIABLES
# export PAGER="moar --no-statusbar"

if command -v pass >/dev/null 2>&1; then
	export OPENAI_API_KEY="$(pass show openai/api-key 2>/dev/null)"
	export SRC_ACCESS_TOKEN="$(pass show sg/token 2>/dev/null)"
	export SRC_ENDPOINT="$(pass show sg/endpoint 2>/dev/null)"
	export GITLAB_TOKEN="$(pass show gitlab/access-token 2>/dev/null)"
	export GITHUB_TOKEN="$(pass show github/token 2>/dev/null)"
	export OPEN_BUTTON_TOKEN="$(pass show open_button/token 2>/dev/null)"
	export MINI_FLUX_TOKEN="$(pass show miniflux/pika-token-1 2>/dev/null)"
	export SLSKD_SLSK_USERNAME="$(pass show slskd/slsk_username 2>/dev/null)"
	export SLSKD_SLSK_PASSWORD="$(pass show slskd/slsk_password 2>/dev/null)"
	export SLSKD_USERNAME="$(pass show slskd/username 2>/dev/null)"
	export SLSKD_PASSWORD="$(pass show slskd/password 2>/dev/null)"
	export SYNTHETIC_API_KEY="$(pass show synthetic.new/api-key 2>/dev/null)"
	export MINIFLUX_API_KEY="$(pass show rss.marcel.cool | grep "api:" | cut -d ' ' -f 2 2>/dev/null)"
	export KAGI_SESSION_TOKEN="$(pass show kagi/api-token 2>/dev/null)"
fi

export _JAVA_AWT_WM_NONREPARENTING=1
export AWT_TOOLKIT=MToolkit
export GDK_BACKEND=wayland
export ELECTRON_OZONE_PLATFORM_HINT=wayland

export HOMEBREW_NO_AUTO_UPDATE=1
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
export HYPRSHOT_DIR=$HOME/screenshots
# export EDITOR=/home/marcel/.local/share/bob/nvim-bin/nvim
# export SUDO_EDITOR=/home/marcel/.local/share/bob/nvim-bin/nvim
export EDITOR=nvim
export DFT_BACKGROUND=light
export SUDO_EDITOR=nvim
export TERMINAL=foot

if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
	export MOZ_ENABLE_WAYLAND=1
fi

function so() {
	source "$HOME/.bashrc"
}

syn() {
	if [ $# -ne 1 ]; then
		echo "Usage: syn <word>"
		return 1
	fi

	local result
	result=$(
		curl -s "https://api.dictionaryapi.dev/api/v2/entries/en/$1" |
			jq -r '.[].meanings[]? | (.synonyms[]?, .definitions[]?.synonyms[]?)'
	)
	if [ -z "$result" ]; then
		echo "No synonyms found"
	else
		echo "$result"
	fi
}

def() {
	if [ $# -ne 1 ]; then
		echo "Usage: def <word>"
		return 1
	fi

	local result
	result=$(
		curl -s "https://api.dictionaryapi.dev/api/v2/entries/en/$1" |
			jq -r '.[].meanings[]?.definitions[]?.definition'
	)
	if [ -z "$result" ]; then
		echo "No definitions found"
	else
		echo "$result"
	fi
}

wttr() {
	if [ -z "$1" ]; then
		echo 'City argument missing'
		echo 'wttr <city>'
		return 1
	fi
	curl "wttr.in/$1?format=Location:%l\nCondition:%C\nTemp:%t\nFeels:%f\nWind:%w\nHumidity:%h\nPressure:%P\nPrecip:%p"
}

# No need with nix, use the tempshell script instead
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
#
# if command -v pyenv 1>/dev/null 2>&1; then
#   eval "$(pyenv init - bash)"
# fi

export PATH="/home/$USER/.local/share/bob/nvim-bin:$PATH"
export PATH=$PATH:/usr/local/bin:/snap/bin
export PATH="/home/$USER/.local/bin:$PATH"
export PATH="/home/$USER/.cargo/bin:$PATH"
for d in "$HOME/scripts" "$HOME/scripts"/*; do
	[ -d "$d" ] && PATH="$d:$PATH"
done

if [ -z "$SOURSES_RUNNING" ]; then
	export SOURSES_RUNNING=1
	# Replace this shell with the sourses recorder (PTY spawn + indexing) exec ~/clones/own/sourses/target/debug/sourses record
fi
# . "$HOME/.cargo/env"

export _ZO_DOCTOR=0

gstp() {
	git status --porcelain "$@" | awk '$1 ~ /^M/ { print $2 }' | paste -sd ' '
}

# if [[ $- == *i* ]] && [[ -t 0 ]] && command -v tarea >/dev/null 2>&1; then
# 	tarea
# fi

mkdir -p ~/.cache/bash-completions
if command -v tarea >/dev/null 2>&1; then
	[ -f ~/.cache/bash-completions/tarea.bash ] || tarea --completions bash >~/.cache/bash-completions/tarea.bash
	# shellcheck disable=SC1090
	. ~/.cache/bash-completions/tarea.bash
fi

# if command -v gcs >/dev/null 2>&1; then
# 	eval "$(gcs --completion bash)"
# fi

if command -v timer >/dev/null 2>&1; then
	eval "$(timer completion bash)"
fi

unset LS_COLORS
