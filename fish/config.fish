# Sourced from ~/.config/fish/config.fish:
#
#   source ~/dotfiles/fish/config.fish
#
# Fish ships autosuggestions, syntax highlighting and completions, so the
# zsh plugins have no counterpart here.

set -gx DOTFILES $HOME/dotfiles
set -p fish_function_path $DOTFILES/fish/functions

# -------------------------------------------------------------------
# Environment
# -------------------------------------------------------------------
set -gx LESS '--ignore-case --raw-control-chars'
set -gx PAGER less
set -gx GIT_EDITOR nvim
set -gx VISUAL nvim
set -gx EDITOR $VISUAL

set -gx TERM st-256color
set -gx TERMINAL st-256color
command -q nvim; and set -gx MANPAGER 'nvim +Man!'

set -gx LC_COLLATE C
set -gx LC_CTYPE en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
set -gx LANG en_US.UTF-8

set -gx GOPATH $HOME/go
set -gx GOBIN $GOPATH/bin

# fish_add_path skips missing and duplicate entries.
fish_add_path -gP /usr/local/bin /usr/local/sbin $GOBIN $HOME/.config/emacs/bin
fish_add_path -gaP /usr/local/go/bin $HOME/.cargo/bin $HOME/.local/bin

status is-interactive; or return

# -------------------------------------------------------------------
# Shell
# -------------------------------------------------------------------
set -g fish_greeting
set -g fish_transient_prompt 1

# -------------------------------------------------------------------
# Abbreviations
# -------------------------------------------------------------------
abbr -a ec emacsclient

# tmux
abbr -a t tmux
abbr -a tma 'tmux attach -t'
abbr -a tmlw 'tmux list-windows'
abbr -a tmls 'tmux list-sessions'
abbr -a tmd 'tmux detach-client'
abbr -a tmk 'tmux kill-session -t'
abbr -a tmnw 'tmux new-window'
abbr -a tmkw 'tmux kill-window'

# directory movement; `..` and `dir/` already cd on their own
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'
abbr -a bk 'cd -'
abbr -a dh dirh
abbr -a m 'cd ~/go/src/github.com/absmach/magistrala'
abbr -a mui 'cd ~/magistrala-ui'
abbr -a fx 'cd ~/go/src/github.com/absmach/fluxmq'

# directory information
abbr -a lh 'ls -d .*'
abbr -a lsd 'ls -aFhlG'
abbr -a l 'ls -al'
abbr -a ll 'ls -GFhl'
abbr -a dus 'du -sckx * | sort -nr'
abbr -a wordy 'wc -w * | sort | tail -n10'
abbr -a filecount 'find . -type f | wc -l'

# git
abbr -a ga 'git add'
abbr -a gs 'git status'
abbr -a gc 'git commit -m'
abbr -a gca 'git commit --amend'
abbr -a gta 'git tag -a -m'
abbr -a gl 'git log'
abbr -a gpl "git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
abbr -a grl 'git reflog'
abbr -a gb 'git branch'
abbr -a gco 'git checkout'
abbr -a gcb 'git checkout -b'
abbr -a gcp 'git cherry-pick'
abbr -a gr 'git rebase'
abbr -a gri 'git rebase -i'
abbr -a gcl 'git clone'
abbr -a gp 'git push'
abbr -a gpu 'git pull --rebase'
abbr -a gra 'git remote add'
abbr -a grr 'git remote rm'
abbr -a gd 'git diff'
abbr -a gdt 'git difftool'
abbr -a gm 'git merge'
abbr -a gms 'git merge --squash'
abbr -a gmf 'git merge --no-ff'
abbr -a gmt 'git mergetool'

# docker
abbr -a dps 'docker ps'
abbr -a dl 'docker logs'
abbr -a drma 'docker rm (docker ps -a -q) -f'

# other
abbr -a terminal alacritty
abbr -a code codium
