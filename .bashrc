# shellcheck disable=2148

export GIT_PROMPT=true
export KUBE_PROMPT=true
export NIX_PROMPT=true
export VI_MODE_PROMPT=true

source ~/.bash_aliases

if [[ $- == *i* ]] && [[ -t 0 ]]; then
	source ~/clones/forks/xelabash/xela.bash
fi

gpsup() {
	local branch
	branch=$(git symbolic-ref --short HEAD 2>/dev/null)
	git push --set-upstream origin "$branch"
}

set -o vi

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
_carapace_lazy_init() {
	if [[ -z "$_CARAPACE_INITIALIZED" ]]; then
		source <(carapace _carapace)
		export _CARAPACE_INITIALIZED=1
	fi
	# Call the original complete_func
	compopt -o default
	COMPREPLY=()
}
complete -F _carapace_lazy_init -D
__post_first_prompt_init() {
	eval "$(direnv hook bash)"
	eval "$(atuin init bash --disable-up-arrow)"
	eval "$(zoxide init bash)"
	[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
	PROMPT_COMMAND="${PROMPT_COMMAND//__post_first_prompt_init;/}"
	unset -f __post_first_prompt_init
}

# Initialize immediately in tmux (after xela.bash is loaded), otherwise use deferred init
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

# pass
SECRETS_CACHE=~/.cache/sh/secret-env
if [ -f "$SECRETS_CACHE" ] && [ $(($(date +%s) - $(stat -c %Y "$SECRETS_CACHE"))) -lt 3600 ]; then
	. "$SECRETS_CACHE"
else
	mkdir -p ~/.cache/sh
	{
		echo "export OPENAI_API_KEY=$(pass show openai/api-key)"
		echo "export SRC_ACCESS_TOKEN=$(pass show sg/token)"
		echo "export SRC_ENDPOINT=$(pass show sg/endpoint)"
		echo "export GITLAB_TOKEN=$(pass show gitlab/access-token)"
		echo "export GITHUB_TOKEN=$(pass show github/token)"
		echo "export ANTHROPIC_API_KEY=$(pass show anthropic/api-key)"
	} >"$SECRETS_CACHE"

	. "$SECRETS_CACHE"
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
	. ~/.cache/bash-completions/tarea.bash
fi

# need to go back and work on gcs again so it generates completions
# if command -v gcs >/dev/null 2>&1; then
# 	eval "$(gcs --completion bash)"
# fi
