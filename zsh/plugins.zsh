source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

source <(kubectl completion zsh)


# Use ripgrep combined with preview
# find-in-file - usage: fif <searchTerm>

zle     -N    __fif__
bindkey -M emacs '^F' __fif__
bindkey -M vicmd '^F' __fif__
bindkey -M viins '^F' __fif__

# Edit in $VISUAL
autoload edit-command-line; zle -N edit-command-line
bindkey -M vicmd v edit-command-line

__fif__() {
	RG_PREFIX="rga --files-with-matches"
	FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'"
		fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
			--phony -q "$1" \
			--bind "change:reload:$RG_PREFIX {q}" \
			--preview-window="75%:wrap" \
	| xargs $EDITOR
}
