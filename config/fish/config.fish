# Sourced from ~/.config/fish/config.fish:
#
#   source ~/dotfiles/config/fish/config.fish
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
set -g fish_color_normal eceff4
set -g fish_color_command a3be8c
set -g fish_color_keyword bf616a
set -g fish_color_quote ebcb8b
set -g fish_color_redirection 88c0d0
set -g fish_color_end d08770
set -g fish_color_error bf616a
set -g fish_color_param e5e9f0
set -g fish_color_option e5e9f0
set -g fish_color_comment 7b88a1
set -g fish_color_operator e5e9f0
set -g fish_color_escape b48ead
set -g fish_color_autosuggestion 7b88a1
set -g fish_color_valid_path --underline
set -g fish_color_cancel bf616a --reverse
set -g fish_color_selection --background=3b4252
set -g fish_color_search_match --background=434c5e
set -g fish_color_history_current --bold
set -g fish_color_cwd a3be8c
set -g fish_color_cwd_root bf616a
set -g fish_color_user a3be8c
set -g fish_color_host 81a1c1
set -g fish_color_host_remote ebcb8b
set -g fish_color_status bf616a
set -g fish_pager_color_prefix 8fbcbb --bold --underline
set -g fish_pager_color_completion eceff4
set -g fish_pager_color_description 7b88a1
set -g fish_pager_color_progress 2e3440 --background=8fbcbb
set -g fish_pager_color_selected_background --background=3b4252
set -g fish_pager_color_selected_completion 8fbcbb

set -g __prompt_color_parent 81a1c1
set -g __prompt_color_dir 81a1c1
set -g __prompt_color_ok a3be8c
set -g __prompt_color_error bf616a
set -g __prompt_color_clean a3be8c
set -g __prompt_color_modified ebcb8b
set -g __prompt_color_conflicted bf616a
set -g __prompt_color_meta 7b88a1
set -g __prompt_color_duration bf616a
set -g __prompt_color_jobs a3be8c
set -g __prompt_color_root ebcb8b
set -g __prompt_color_remote d08770
set -g __prompt_color_time 88c0d0
# theme:end

# -------------------------------------------------------------------
# Abbreviations
# -------------------------------------------------------------------
abbr -a ec emacsclient

# bash-style history expansion: !! is the previous command, !$ its last
# argument. Abbreviations rather than real expansion, so the line is rewritten
# in place and visible before it runs -- `sudo !!` becomes the full command.
abbr -a !! --position anywhere --function __history_bang_last
abbr -a '!$' --position anywhere --function __history_bang_arg

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
abbr -a dh dirh
abbr -a m 'cd ~/go/src/github.com/absmach/magistrala'
abbr -a fx 'cd ~/go/src/github.com/absmach/fluxmq'

# directory information
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

# other
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
    # Qt takes its palette from the GTK theme, which config/gtk-3.0/gtk.css has
    # already made gruvbox. qgtk3 is the one platform theme that ships for both
    # Qt 5 and Qt 6, so a single name covers both and nothing extra is needed.
    #
    # KDE's own apps — okular, kdenlive, kdeconnect, kwave — ignore this and
    # paint themselves in Breeze. They read config/qt/kdeglobals instead, but
    # only once plasma-integration provides the theme that hands it to them:
    #
    #     sudo pacman -S plasma-integration
    #     set -gx QT_QPA_PLATFORMTHEME kde
    #
    # That name then covers every Qt app, KDE or not, straight from kdeglobals.
    set -gx QT_QPA_PLATFORMTHEME gtk3
    set -gx SDL_VIDEODRIVER wayland
    set -gx _JAVA_AWT_WM_NONREPARENTING 1

    if test -z "$WAYLAND_DISPLAY" -a -z "$DISPLAY" -a "$XDG_VTNR" = 1
        # dbus-run-session would spawn its own bus and keep sway as its child,
        # which buries the whole session one level down in every process tree.
        # systemd already provides the user bus on $XDG_RUNTIME_DIR/bus via the
        # static dbus.socket, so point at that and exec sway as the root.
        set -gx DBUS_SESSION_BUS_ADDRESS "unix:path=$XDG_RUNTIME_DIR/bus"
        exec sway
    end
end
