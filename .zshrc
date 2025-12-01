# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/.bash_aliases

# alias zshalais="source ~/.zshrc"

# shellcheck disable=2148

# source $(rund zsh)
eval "$(zoxide init zsh)"

# pnpm
export PNPM_HOME="/Users/m.manzanares/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
#
GITHUB_TOKEN=$(pass show github/token)
export GITHUB_TOKEN

# eval "$(starship init zsh)"
eval "$(direnv hook zsh)"

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# fnm
export PATH="/Users/m.manzanares/Library/Application Support/fnm:$PATH"
eval "$(fnm env)"

# bun completions
[ -s "/Users/m.manzanares/.bun/_bun" ] && source "/Users/m.manzanares/.bun/_bun"
source ~/clones/external/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

unset LS_COLORS
