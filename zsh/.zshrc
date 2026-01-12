# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/dotfiles/zsh/options.zsh
source ~/dotfiles/zsh/exports.zsh
source ~/dotfiles/zsh/prompt.zsh
source ~/dotfiles/zsh/completion.zsh
source ~/dotfiles/zsh/aliases.zsh
source ~/dotfiles/zsh/bindings.zsh
source ~/dotfiles/zsh/history.zsh
source ~/dotfiles/zsh/plugins.zsh

zstyle ':completion:*'  list-colors '=*=32'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# eval "$(starship init zsh)"
