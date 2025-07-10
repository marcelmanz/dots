# shellcheck disable=2148


export GIT_PROMPT=true
export KUBE_PROMPT=true
export NIX_PROMPT=true
export VI_MODE_PROMPT=true

source ~/.bash_aliases
source ~/clones/forks/xelabash/xela.bash

alias gpsup="git push --set-upstream origin $(git symbolic-ref --short HEAD 2>/dev/null)"

set -o vi

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
source <(carapace _carapace)
eval "$(direnv hook bash)"
# eval "$(atuin init bash --disable-up-arrow)"

# Use bash-completion, if available
# [[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] &&
# 	. /usr/share/bash-completion/bash_completion

# Start gpg-agent if not already running
GPG_AGENT_INFO=$(gpgconf --list-dirs agent-socket)
export GPG_AGENT_INFO

GPG_TTY=$(tty)
export GPG_TTY

# If SSH_AUTH_SOCK is not set, set it to gpg-agent's SSH socket
if [ -z "$SSH_AUTH_SOCK" ] && [ -S "$GPG_AGENT_INFO.ssh" ]; then
	export SSH_AUTH_SOCK="$GPG_AGENT_INFO.ssh"
fi

# source "$HOME/.rye/env"
# source rund bash
# eval "$(starship init bash)"

# ENV. VARIABLES
# export PAGER="moar --no-statusbar"

# pass
# OPENAI_API_KEY=$(pass show openai/api-key)
# export OPENAI_API_KEY
# GITHUB_TOKEN=$(pass show github/token)
# export GITHUB_TOKEN
# SRC_ACCESS_TOKEN=$(pass show sg/token)
# export SRC_ACCESS_TOKEN
# SRC_ENDPOINT=$(pass show sg/endpoint)
# export SRC_ENDPOINT
# GITLAB_TOKEN=$(pass show gitlab/access-token)
# export GITLAB_TOKEN

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
export TERMINAL=alacritty

ANTHROPIC_API_KEY=$(pass show anthropic/api-key)
export ANTHROPIC_API_KEY

if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
	export MOZ_ENABLE_WAYLAND=1
fi

function so() {
	source "$HOME/.bashrc"
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

if [ -z "$SOURSES_RUNNING" ]; then
  export SOURSES_RUNNING=1
  # Replace this shell with the sourses recorder (PTY spawn + indexing) exec ~/clones/own/sourses/target/debug/sourses record
fi
. "$HOME/.cargo/env"

eval "$(zoxide init bash)"
export _ZO_DOCTOR=0
