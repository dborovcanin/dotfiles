#!/usr/bin/env bash
set -euo pipefail

# Copies the configs that programs insist on reading from their own locations.
#
# Usage: install.sh [--dry-run] [--no-backup] [--no-reload]
#        --dry-run   print what would happen and change nothing
#        --no-backup overwrite without keeping the file that was there
#        --no-reload copy the files and leave running programs alone
#
# Colours are not written here: scripts/theme.sh writes them into the repo, and
# this copies the result out. Run theme.sh first if a theme has just changed.
#
# Only half the repo is listed below, because only half of it is copied. Every
# config a window manager reads by path — dbar, dunst, picom, polybar, rofi, the
# i3status bar, bin/search and all of scripts/ — is referenced as
# $HOME/dotfiles/... from the sway, i3 and niri configs, so it runs from the
# clone and must not be duplicated into ~/.config, where it would go stale.
#
# Anything already identical is left alone, so a second run reports nothing.
#
# This copies one way, repo to home, and overwrites whatever is there. When a
# file in home has drifted ahead — an installer appended to ~/.zshrc, an app
# rewrote its own config — bring that change back into the repo first, or this
# will bury it. --dry-run lists everything that would be replaced, which is the
# cheap way to find out.
#
# btop is the one copied here that rewrites its own config every time it quits,
# settings changed from inside it included. The repo copy goes stale by the program
# being used, so copy ~/.config/btop/btop.conf back into the repo before running
# this, or the last thing changed in btop is what gets overwritten.
#
# A destination that is a symlink is removed and replaced by a real file rather
# than written through. cp follows a link and would overwrite whatever sits at
# the far end, which need not be yours: ~/.config/starship.toml arrived as a
# link into ~/.local/share/mybash. Backups dereference for the same reason, so
# that what is saved is the content that was at risk and not just a path.
#
# Replaced files are kept under ~/.config/dotfiles-backup-<timestamp>, laid out
# the way they sat in home, unless --no-backup says otherwise.
#
# The desktop colour scheme is set from the theme that theme.sh applied last.
# libadwaita and the Qt platform theme take light or dark from there rather than
# from any file, so a light theme on a desktop still set to dark gets its own
# background with libadwaita's light-on-dark text over it - unreadable, and the
# reason this is done here rather than left as advice.
#
# What is running is then told to re-read its configuration, so that a copy and
# a visible change are the same step. Only programs that are actually running
# are touched, and only through the mechanism each one documents: sway and i3
# reload over their IPC, dunst over dunstctl, picom on SIGUSR1, polybar by
# restarting its bars, tmux by sourcing its file again, and foot by switching
# between the theme blocks its config already carries. niri watches its own
# config file and needs nobody's help. dbar is sent the realtime signal its config
# names, when the running bar is actually watching for it - /proc says which
# signals a process catches, and one it does not catch would kill it - and is
# restarted with its own argv otherwise.
#
# This runs whether or not a file changed here, because the configs that are
# read from the clone - dbar, dunst, picom, polybar, the i3 status bar - are
# rewritten by theme.sh without this script seeing it. Reloading is cheap and
# repeatable; --no-reload turns it off.
#
# Two things are left to do by hand, printed on the way out: tlp.conf belongs to
# /etc and needs root, and a running helix re-reads its config on `:config-reload`
# - it is not signalled here, because an editor that does not handle the signal
# dies of it and takes unsaved buffers with it. X11 clients also want
# `xrdb -merge ~/.Xresources` before the cursor and colours in it take effect,
# which this runs when xrdb is there.

usage() {
    sed -n '4,${/^#/!q;s/^# \{0,1\}//p}' "$0"
}

root=$(realpath "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/..")
backup=$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)
dry_run=0
keep_backup=1
do_reload=1

# src|dst, one per line. src is relative to the repo, dst absolute.
targets() {
    cat <<EOF
config/niri/config.kdl|$HOME/.config/niri/config.kdl
config/sway/config|$HOME/.config/sway/config
config/i3/config|$HOME/.config/i3/config
config/foot/foot.ini|$HOME/.config/foot/foot.ini
config/alacritty/alacritty.toml|$HOME/.config/alacritty/alacritty.toml
config/helix/config.toml|$HOME/.config/helix/config.toml
config/btop/btop.conf|$HOME/.config/btop/btop.conf
config/starship/starship.toml|$HOME/.config/starship.toml
config/gtk-3.0/gtk.css|$HOME/.config/gtk-3.0/gtk.css
config/gtk-3.0/settings.ini|$HOME/.config/gtk-3.0/settings.ini
config/gtk-4.0/gtk.css|$HOME/.config/gtk-4.0/gtk.css
config/gtk-4.0/settings.ini|$HOME/.config/gtk-4.0/settings.ini
config/gtk-2.0/gtkrc.mine|$HOME/.gtkrc-2.0.mine
config/qt/kdeglobals|$HOME/.config/kdeglobals
config/qt/Dotfiles.colors|$HOME/.local/share/color-schemes/Dotfiles.colors
tmux/.tmux.conf|$HOME/.tmux.conf
zsh/.zshrc|$HOME/.zshrc
.Xresources|$HOME/.Xresources
.Xdefaults|$HOME/.Xdefaults
.spacemacs|$HOME/.spacemacs
EOF
}

# fish is the one file that is sourced rather than copied, so that editing the
# clone changes the running shell. Everything else in config/fish is reached
# from there: config.fish puts config/fish/functions on fish_function_path.
fish_line="source \$HOME/dotfiles/config/fish/config.fish"

installed=0
skipped=0
backed_up=0

say() { printf '  %-10s %s\n' "$1" "$2"; }

# Keeps the file that is about to be overwritten, once per run, under one
# timestamped directory that mirrors the path it came from.
#
# A symlink is dereferenced on the way in: copying the link itself would save
# nothing but a path, and the content it points at is exactly what is at risk.
save() {
    local dst=$1 rel=${1#"$HOME"/} dest
    ((keep_backup)) || return 0
    dest=$backup/$rel
    ((dry_run)) && return 0
    mkdir -p "$(dirname "$dest")"
    cp -L "$dst" "$dest" 2>/dev/null || cp -a "$dst" "$dest"
    ((++backed_up))
}

put() {
    local src=$root/$1 dst=$2
    if [[ ! -f $src ]]; then
        say "missing" "${1} is not in the repo" >&2
        return 1
    fi
    if [[ -f $dst ]] && cmp -s "$src" "$dst"; then
        ((++skipped))
        return 0
    fi
    if [[ -e $dst || -L $dst ]]; then
        save "$dst"
        if [[ -L $dst ]]; then
            say "replace" "${dst/#"$HOME"/\~} (was a link to $(readlink "$dst"))"
        else
            say "replace" "${dst/#"$HOME"/\~}"
        fi
    else
        say "create" "${dst/#"$HOME"/\~}"
    fi
    ((++installed))
    ((dry_run)) && return 0
    mkdir -p "$(dirname "$dst")"
    # The link is removed rather than written through. cp follows a symlink and
    # would overwrite whatever it points at, which is somebody else's file:
    # ~/.config/starship.toml is a link into ~/.local/share/mybash.
    rm -f "$dst"
    cp "$src" "$dst"
}

# fish: the target holds one source line, not a copy of the config.
put_fish() {
    local dst=$HOME/.config/fish/config.fish
    if [[ -f $dst ]] && [[ $(cat "$dst") == "$fish_line" ]]; then
        ((++skipped))
        return 0
    fi
    if [[ -e $dst || -L $dst ]]; then
        save "$dst"
        say "replace" "${dst/#"$HOME"/\~} (source line)"
    else
        say "create" "${dst/#"$HOME"/\~} (source line)"
    fi
    ((++installed))
    ((dry_run)) && return 0
    mkdir -p "$(dirname "$dst")"
    rm -f "$dst"
    printf '%s\n' "$fish_line" >"$dst"
}

while (($#)); do
    case $1 in
        --dry-run) dry_run=1 ;;
        --no-backup) keep_backup=0 ;;
        --no-reload) do_reload=0 ;;
        -h | --help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

((dry_run)) && echo "Dry run; nothing is written."

while IFS='|' read -r src dst; do
    [[ -n $src ]] || continue
    put "$src" "$dst"
done < <(targets)
put_fish

# light or dark, as the theme applied last asked for; empty when there is no
# readable theme to ask. Both the desktop setting and foot's colours want this.
theme_scheme() {
    local name file
    name=$(cat "$root/themes/current" 2>/dev/null) || return 0
    [[ -n ${name:-} ]] || return 0
    if [[ $name == */* ]]; then file=$name; else file=$root/themes/$name.sh; fi
    [[ -r $file ]] || return 0

    # Sourced in a subshell: these files set THEME_* wholesale and this script
    # has no business carrying them afterwards.
    (
        # shellcheck disable=SC1090
        THEME_SCHEME=dark
        source "$root/themes/gruvbox.sh" 2>/dev/null
        source "$file" 2>/dev/null
        [[ $THEME_SCHEME == light ]] && echo light || echo dark
    )
}

# The theme applied last decides whether the desktop asks for light or dark.
sync_scheme() {
    local name scheme want have
    name=$(cat "$root/themes/current" 2>/dev/null) || return 0
    scheme=$(theme_scheme)
    [[ -n $scheme ]] || return 0
    command -v gsettings >/dev/null || return 0

    [[ $scheme == light ]] && want=prefer-light || want=prefer-dark
    have=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d \')
    [[ $have == "$want" ]] && return 0
    say "scheme" "$want (was $have), for $name"
    ((dry_run)) && return 0
    gsettings set org.gnome.desktop.interface color-scheme "$want"
}

# X11 clients read the resource database once, at load.
sync_xrdb() {
    command -v xrdb >/dev/null || return 0
    [[ -n ${DISPLAY:-} || -n ${WAYLAND_DISPLAY:-} ]] || return 0
    [[ -f $HOME/.Xresources ]] || return 0
    ((dry_run)) && return 0
    xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
}

# --- Telling what is running to re-read what was just written ---------------
#
# Every one of these is a no-op unless that program is running, so the same
# script is correct on a machine that has none of them, and a failure to reload
# is never a failure to install: the files are already on disk by this point.

running() { pgrep -x "$1" >/dev/null 2>&1; }

reload_sway() {
    [[ -n ${SWAYSOCK:-} ]] || return 0
    command -v swaymsg >/dev/null || return 0
    say "reload" "sway"
    ((dry_run)) || swaymsg -q reload || true
}

reload_i3() {
    command -v i3-msg >/dev/null || return 0
    running i3 || return 0
    say "reload" "i3"
    ((dry_run)) || i3-msg -q reload >/dev/null 2>&1 || true
}

# dunst was started with -config pointing into the clone, so the reload has to
# name the same file. Left bare it would re-read the default path instead and
# quietly forget the theme.
reload_dunst() {
    command -v dunstctl >/dev/null || return 0
    running dunst || return 0
    say "reload" "dunst"
    ((dry_run)) || dunstctl reload "$root/config/dunst/dunstrc" >/dev/null 2>&1 || true
}

reload_picom() {
    running picom || return 0
    say "reload" "picom"
    ((dry_run)) || pkill -USR1 -x picom || true
}

reload_polybar() {
    command -v polybar-msg >/dev/null || return 0
    running polybar || return 0
    say "reload" "polybar"
    ((dry_run)) || polybar-msg cmd restart >/dev/null 2>&1 || true
}

reload_tmux() {
    command -v tmux >/dev/null || return 0
    tmux has-session >/dev/null 2>&1 || return 0
    say "reload" "tmux"
    ((dry_run)) || tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
}

# foot has no config reload. What it does have is [colors-dark] and
# [colors-light] in the file it already read, and a signal that chooses between
# them - which is the half of foot.ini a theme change actually moves.
reload_foot() {
    local scheme
    running foot || return 0
    scheme=$(theme_scheme)
    [[ -n $scheme ]] || return 0
    say "reload" "foot ($scheme colours)"
    ((dry_run)) && return 0
    if [[ $scheme == light ]]; then
        pkill -USR2 -x foot || true
    else
        pkill -USR1 -x foot || true
    fi
}

# The realtime signal offset the bar's config asks to be re-read on, if it asks.
dbar_reload_offset() {
    sed -n 's/^[[:space:]]*reload_signal[[:space:]]*=[[:space:]]*\([0-9]\{1,\}\).*/\1/p' \
        "$root/config/dbar/config.toml" 2>/dev/null | head -n 1
}

# Whether process $1 has a handler installed for signal number $2.
#
# SigCgt in /proc/PID/status is the mask of signals the process catches, one bit per
# signal, so this is the process itself answering rather than a guess from its config.
# It has to be asked: a realtime signal that nothing catches kills what it is sent to.
catches() {
    local mask
    mask=$(sed -n 's/^SigCgt:[[:space:]]*//p' "/proc/$1/status" 2>/dev/null) || return 1
    [[ -n $mask ]] || return 1
    (((0x$mask >> ($2 - 1)) & 1))
}

# dbar reads its config once. A bar whose config names a reload signal, and that was
# started late enough to be watching for it, is told to read the file again; anything
# else is restarted. Signalling is worth the check because a restart takes the tray with
# it - every application has to register with the new bar, and some never do until they
# are restarted themselves.
reload_dbar() {
    local offset number pid
    command -v dbar >/dev/null || return 0
    running dbar || return 0
    offset=$(dbar_reload_offset)
    number=""
    [[ -n $offset ]] && number=$(kill -l "RTMIN+$offset" 2>/dev/null || true)
    for pid in $(pgrep -x dbar); do
        if [[ -n $number ]] && catches "$pid" "$number"; then
            say "reload" "dbar (SIGRTMIN+$offset)"
            ((dry_run)) || kill -s "RTMIN+$offset" "$pid" 2>/dev/null || true
            continue
        fi
        say "reload" "dbar (restart)"
        ((dry_run)) && continue
        restart_dbar "$pid"
    done
}

# Start a bar again with the argv it was started with, because sway and niri start it
# differently: niri points it at a copy under $XDG_RUNTIME_DIR with the layer rewritten,
# and that copy is regenerated here or the restart would put the pre-theme file back on
# screen. The rewrite is the line in config/niri/config.kdl, and the two have to move
# together.
restart_dbar() {
    local pid=$1 conf i argv
    mapfile -d '' -t argv <"/proc/$pid/cmdline" 2>/dev/null || return 0
    ((${#argv[@]})) || return 0
    conf=""
    for ((i = 0; i < ${#argv[@]}; i++)); do
        [[ ${argv[i]} == -c ]] && conf=${argv[i + 1]:-}
    done
    if [[ -n $conf && $conf != "$root"/* && -f $root/config/dbar/config.toml ]]; then
        sed 's/^layer = "bottom"$/layer = "top"/' \
            "$root/config/dbar/config.toml" >"$conf"
    fi
    kill "$pid" 2>/dev/null || return 0
    # Wait for the surface to go before asking for another one.
    for _ in $(seq 20); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
    done
    setsid "${argv[@]}" >/dev/null 2>&1 &
}

reload_running() {
    ((do_reload)) || return 0
    # niri watches its own config file and has already reloaded from the copy
    # above; alacritty and kitty watch theirs. None of the three is signalled.
    reload_sway
    reload_i3
    reload_dunst
    reload_picom
    reload_polybar
    reload_tmux
    reload_foot
    reload_dbar
}

sync_scheme
sync_xrdb
reload_running

printf '\n%d %s, %d already current' "$installed" \
    "$( ((dry_run)) && echo "to install" || echo installed )" "$skipped"
((backed_up)) && printf ', %d saved under %s' "$backed_up" "${backup/#"$HOME"/\~}"
printf '.\n'

cat <<'EOF'

Not copied, on purpose:
  etc/tlp.conf          belongs to /etc and needs root:
                        sudo cp etc/tlp.conf /etc/tlp.conf
  dbar, dunst, picom, polybar, rofi, i3/status.toml, bin, scripts
                        read from the clone by the window manager configs

Reloaded above, where the program was running: sway, i3, dunst, picom, polybar,
tmux, foot's colour block, and dbar on its reload signal, or by restarting it
when the running bar predates the signal. niri, alacritty and kitty
watch their own config files. Left by hand: a running helix wants
`:config-reload` typed into it, since an editor that does not handle the signal
dies of it, and GTK and Qt apps pick up colours when they next start. The
desktop colour scheme and the X resource database were handled above.
EOF
