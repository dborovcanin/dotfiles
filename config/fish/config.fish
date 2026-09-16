# Sourced from ~/.config/fish/config.fish:
#
#   source ~/dotfiles/fish/config.fish
#
# Fish ships autosuggestions, syntax highlighting and completions, so the
# zsh plugins have no counterpart here.

set -gx DOTFILES $HOME/dotfiles
set -p fish_function_path $DOTFILES/config/fish/functions

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
# Colours, written by scripts/theme.sh
# -------------------------------------------------------------------
# theme:begin fish
set -g fish_color_normal ebdbb2
set -g fish_color_command b8bb26
set -g fish_color_keyword fb4934
set -g fish_color_quote fabd2f
set -g fish_color_redirection 8ec07c
set -g fish_color_end fe8019
set -g fish_color_error fb4934
set -g fish_color_param d5c4a1
set -g fish_color_option d5c4a1
set -g fish_color_comment 928374
set -g fish_color_operator fe8019
set -g fish_color_escape d3869b
set -g fish_color_autosuggestion 928374
set -g fish_color_valid_path --underline
set -g fish_color_cancel fb4934 --reverse
set -g fish_color_selection --background=3c3836
set -g fish_color_search_match --background=504945
set -g fish_color_history_current --bold
set -g fish_color_cwd b8bb26
set -g fish_color_cwd_root fb4934
set -g fish_color_user b8bb26
set -g fish_color_host 83a598
set -g fish_color_host_remote fabd2f
set -g fish_color_status fb4934
set -g fish_pager_color_prefix fabd2f --bold --underline
set -g fish_pager_color_completion ebdbb2
set -g fish_pager_color_description 928374
set -g fish_pager_color_progress 282828 --background=fabd2f
set -g fish_pager_color_selected_background --background=3c3836
set -g fish_pager_color_selected_completion fabd2f

set -g __prompt_color_parent 458588
set -g __prompt_color_dir 83a598
set -g __prompt_color_ok b8bb26
set -g __prompt_color_error fb4934
set -g __prompt_color_clean b8bb26
set -g __prompt_color_modified fabd2f
set -g __prompt_color_conflicted fb4934
set -g __prompt_color_meta 928374
set -g __prompt_color_duration cc241d
set -g __prompt_color_jobs 98971a
set -g __prompt_color_root fabd2f
set -g __prompt_color_remote fe8019
set -g __prompt_color_time 689d6a
# theme:end

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

# -------------------------------------------------------------------
# Wayland session (login shell on tty1)
# -------------------------------------------------------------------
if status is-login
    set -gx XDG_CURRENT_DESKTOP sway
    set -gx XDG_SESSION_TYPE wayland
    # /etc/environment pins GTK_THEME=Orchis-Dark and pam_env sets it before this
    # file runs, which pre-empts the gruvbox gtk.css in config/gtk-*. It is
    # cleared rather than set to a theme: GTK 4 has no theme by that name on
    # disk, so any value at all makes it fall back to a half-built theme. With
    # nothing set, GTK 3 takes the name from settings.ini, GTK 4 takes dark from
    # the desktop portal, and both then read the gruvbox colours from gtk.css.
    set -e GTK_THEME
    set -gx MOZ_ENABLE_WAYLAND 1
    set -gx QT_QPA_PLATFORM wayland
    # Qt reads one platform theme name and each major version only finds its own
    # plugin, so qt5ct and qt6ct cannot both be named here. Nearly everything Qt
    # on this machine is Qt 6 — krita, okular, flameshot, kdenlive, obs,
    # kdeconnect — so Qt 6 gets it. The qt5ct config is installed alongside for
    # the few Qt 5 holdouts, and swapping this to qt5ct is all it takes.
    set -gx QT_QPA_PLATFORMTHEME qt6ct
    set -gx SDL_VIDEODRIVER wayland
    set -gx _JAVA_AWT_WM_NONREPARENTING 1

    if test -z "$WAYLAND_DISPLAY" -a -z "$DISPLAY" -a "$XDG_VTNR" = 1
        exec dbus-run-session sway
    end
end
