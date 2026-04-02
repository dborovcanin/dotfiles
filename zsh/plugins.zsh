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

# Search file contents with fzf and then choose action

zle -N __fif__
bindkey -M emacs '^F' __fif__
bindkey -M vicmd '^F' __fif__
bindkey -M viins '^F' __fif__

autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

__fif__() {
  local query file action

  query="$LBUFFER"

  file=$(
    fzf \
      --phony \
      --query="$query" \
      --sort \
      --preview='[[ -n {} ]] && rga --pretty --context 5 {q} {}' \
      --preview-window='75%:wrap' \
      --bind="start:reload:rga --files-with-matches --hidden --follow --glob '!.git' {q} || true" \
      --bind="change:reload:rga --files-with-matches --hidden --follow --glob '!.git' {q} || true"
  )

  [[ -z "$file" ]] && zle redisplay && return 0

  action=$(
    printf '%s\n' open insert cancel | \
      fzf --prompt='Action > ' --height=10 --layout=reverse
  )

  case "$action" in
    open)
      "${EDITOR:-nvim}" "$file" </dev/tty >/dev/tty 2>&1
      ;;
    insert)
      LBUFFER+="${(q)file}"
      ;;
    cancel|"")
      ;;
  esac

  zle redisplay
}