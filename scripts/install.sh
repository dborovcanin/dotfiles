#!/usr/bin/env bash
set -euo pipefail

# Copies the configs that programs insist on reading from their own locations.
#
# Usage: install.sh [--dry-run] [--no-backup]
#        --dry-run   print what would happen and change nothing
#        --no-backup overwrite without keeping the file that was there
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
# One thing is left to do by hand, printed on the way out: tlp.conf belongs to
# /etc and needs root. X11 clients also want `xrdb -merge ~/.Xresources` before
# the cursor and colours in it take effect, which this runs when xrdb is there.

usage() {
    sed -n '4,40s/^# \{0,1\}//p' "$0"
}

root=$(realpath "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/..")
backup=$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)
dry_run=0
keep_backup=1

# src|dst, one per line. src is relative to the repo, dst absolute.
targets() {
    cat <<EOF
config/niri/config.kdl|$HOME/.config/niri/config.kdl
config/sway/config|$HOME/.config/sway/config
config/i3/config|$HOME/.config/i3/config
config/foot/foot.ini|$HOME/.config/foot/foot.ini
config/alacritty/alacritty.toml|$HOME/.config/alacritty/alacritty.toml
config/helix/config.toml|$HOME/.config/helix/config.toml
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

# The theme applied last decides whether the desktop asks for light or dark.
sync_scheme() {
    local name file want have
    name=$(cat "$root/themes/current" 2>/dev/null) || return 0
    [[ -n ${name:-} ]] || return 0
    if [[ $name == */* ]]; then file=$name; else file=$root/themes/$name.sh; fi
    [[ -r $file ]] || return 0
    command -v gsettings >/dev/null || return 0

    # Sourced in a subshell: these files set THEME_* wholesale and this script
    # has no business carrying them afterwards.
    want=$(
        # shellcheck disable=SC1090
        THEME_SCHEME=dark
        source "$root/themes/gruvbox.sh" 2>/dev/null
        source "$file" 2>/dev/null
        [[ $THEME_SCHEME == light ]] && echo prefer-light || echo prefer-dark
    )
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

sync_scheme
sync_xrdb

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

Reload what is running: sway and niri re-read their config on reload, dunst and
tmux need restarting, and GTK and Qt apps pick up colours when they next start.
The desktop colour scheme and the X resource database were handled above.
EOF
