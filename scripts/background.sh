#!/usr/bin/env bash
set -euo pipefail

# Picks a picture and renders it into the four backgrounds the desktop reads.
#
# Usage: background.sh [options] [image]
#        -d, --dir DIR     where to look for pictures (default ~/Pictures)
#        -b, --blur SPEC   the blur passed to magick (default 0x6)
#        -q, --quality N   JPEG quality (default 92)
#        -y, --yes         write without asking
#        -n, --no-reload   write the files and leave the screen alone
#            --show        print what is installed now and stop
#
# With no image, DIR is opened in yazi and Enter picks the highlighted file.
# Without yazi every picture under DIR is listed in fzf instead: type to narrow,
# the preview pane draws the image, ctrl-o opens the highlighted one in a real
# viewer, Enter picks. With an image, that file is used and nothing is asked
# except the confirmation.
#
# Four files are written into themes/, from the original every time rather than
# from each other, so a second run cannot blur an already blurred background:
#
#     bg.jpg       bg.png        the wallpaper, for swaybg and feh
#     bg-blur.jpg  bg-blur.png   the same picture blurred, for the lock screen
#
# Both formats are kept because the lock screens disagree: swaylock reads either
# and gets the JPEG, i3lock reads only PNG.
#
# The sway, niri, hyprland and i3 configs name these paths, so whatever is
# drawing the old picture is told to draw the new one once the files are
# written: sway is asked to reload, hyprpaper is told to drop and preload the
# file it is holding, a swaybg started by anything else is started again with
# its own argv, and feh is run again on X11. The lock screens open the file when they
# lock, so they are already current. --no-reload leaves all of that alone.

usage() {
    sed -n '4,32s/^# \{0,1\}//p' "$0"
}

root=$(realpath "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/..")
themes=$root/themes
self=$(realpath "${BASH_SOURCE[0]}")

dir=${BACKGROUND_DIR:-$HOME/Pictures}
blur=0x6
quality=92
assume_yes=0
do_reload=1
picture=

# The extensions worth offering. webp and avif are read by magick and turned
# into the two formats below like anything else.
exts=(jpg jpeg png webp avif bmp tif tiff)

# ---------------------------------------------------------------------------
# The preview pane. fzf runs this script again with __preview, because a
# preview command has to be one string and this way it stays readable.
# ---------------------------------------------------------------------------

# Pixels the preview pane is worth. Cells are assumed 8x16, which is close
# enough for every font here and errs small, so the image never overflows.
preview_px() {
    local cols=${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}} lines=${FZF_PREVIEW_LINES:-24}
    echo $((cols * 8)) $((lines * 16 - 32))
}

# Draws the image with whatever the terminal understands, and says nothing more
# than the dimensions when it understands none of it.
preview() {
    local file=$1 w h iw ih
    read -r w h < <(preview_px)

    printf '%s\n' "${file/#"$HOME"/\~}"
    identify -format '%wx%h  %b  %m\n\n' "$file[0]" 2>/dev/null || echo

    if command -v chafa >/dev/null; then
        # Run by hand chafa probes the terminal and picks sixels and true
        # colour. fzf hands the preview command a pipe instead of a tty, the
        # probe gets nothing back, and chafa drops to its safe fallback of
        # low-colour text symbols, which is the grain. Say what the terminal
        # can do rather than letting it ask.
        local fmt=symbols
        if [[ -n ${KITTY_WINDOW_ID:-} ]]; then
            fmt=kitty
        elif [[ ${TERM:-} == foot* || ${TERM:-} == xterm* || ${TERM:-} == wezterm* || ${TERM:-} == mlterm* || ${TERM:-} == contour* ]]; then
            fmt=sixels
        fi
        chafa -f "$fmt" -c full --polite on \
            --size "${FZF_PREVIEW_COLUMNS:-80}x$((${FZF_PREVIEW_LINES:-24} - 2))" "$file"
    elif [[ -n ${KITTY_WINDOW_ID:-} ]] && command -v kitten >/dev/null; then
        kitten icat --clear --transfer-mode=memory --unicode-placeholder \
            --stdin=no --place="${FZF_PREVIEW_COLUMNS:-80}x$((${FZF_PREVIEW_LINES:-24} - 2))@0x2" "$file"
    elif command -v img2sixel >/dev/null && [[ ${TERM:-} == foot* || ${TERM:-} == xterm* || ${TERM:-} == wezterm* || ${TERM:-} == mlterm* || ${TERM:-} == contour* ]]; then
        # img2sixel keeps the aspect ratio when given one dimension, so the
        # limiting one is worked out here and the other left alone.
        read -r iw ih < <(identify -format '%w %h' "$file[0]" 2>/dev/null || echo "0 0")
        if ((iw > 0 && ih > 0 && iw * h > ih * w)); then
            img2sixel -w "$w" "$file" 2>/dev/null
        else
            img2sixel -h "$h" "$file" 2>/dev/null
        fi
    else
        echo "(no terminal image support: install chafa, or run in foot or kitty)"
    fi
}

# The viewer ctrl-o opens, detached so fzf keeps the terminal.
view() {
    local file=$1 app
    for app in swayimg imv nsxiv feh xdg-open; do
        command -v "$app" >/dev/null || continue
        setsid -f "$app" "$file" >/dev/null 2>&1
        return 0
    done
}

# ---------------------------------------------------------------------------

list_pictures() {
    local find_args=() ext first=1
    for ext in "${exts[@]}"; do
        ((first)) || find_args+=(-o)
        find_args+=(-iname "*.$ext")
        first=0
    done
    find -L "$dir" -type f \( "${find_args[@]}" \) -print 2>/dev/null | sort
}

# yazi owns the terminal while it runs, so it can ask the terminal what it
# draws and answer with sixels or the kitty protocol at the pane's real pixel
# size. fzf hands its preview command a pipe, that question goes unanswered, and
# the image comes back as coloured text cells - the grain. So yazi picks when it
# is here and fzf is the fallback.
choose() {
    [[ -d $dir ]] || {
        echo "background.sh: no directory at $dir" >&2
        exit 1
    }

    if command -v yazi >/dev/null; then
        choose_yazi
    elif command -v fzf >/dev/null; then
        choose_fzf
    else
        echo "background.sh: no yazi or fzf; pass the image as an argument" >&2
        exit 1
    fi
}

# yazi draws on the terminal, so it is pointed at /dev/tty and the picked path
# is the only thing this leaves on stdout for the caller to read.
choose_yazi() {
    local out chosen
    out=$(mktemp)
    yazi --chooser-file="$out" "$dir" >/dev/tty 2>/dev/tty </dev/tty || true
    chosen=$(head -n 1 "$out" 2>/dev/null || true)
    rm -f "$out"

    [[ -n $chosen ]] || {
        echo "Nothing picked." >&2
        exit 1
    }
    printf '%s\n' "$chosen"
}

choose_fzf() {
    local chosen
    chosen=$(list_pictures | fzf \
        --prompt='background> ' \
        --header='Enter picks, ctrl-o opens it in a viewer, Esc gives up' \
        --preview="'$self' __preview {}" \
        --preview-window='right,60%,border-left' \
        --bind="ctrl-o:execute-silent('$self' __view {})") || true

    [[ -n $chosen ]] || {
        echo "Nothing picked." >&2
        exit 1
    }
    printf '%s\n' "$chosen"
}

# Renders one output. Every one starts from the source picture: blurring the
# blur would compound, and a JPEG made from the resized PNG would lose twice.
render() {
    local src=$1 out=$2 blurred=$3
    local args=("$src[0]" -auto-orient -strip)
    if ((blurred)); then args+=(-filter Gaussian -blur "$blur"); fi
    if [[ $out == *.jpg ]]; then args+=(-quality "$quality"); fi
    magick "${args[@]}" "$out"
}

show() {
    local f name
    for name in bg.jpg bg.png bg-blur.jpg bg-blur.png; do
        f=$themes/$name
        if [[ -f $f ]]; then
            printf '  %-12s %s\n' "$name" "$(identify -format '%wx%h  %b' "$f" 2>/dev/null)"
        else
            printf '  %-12s %s\n' "$name" "not written yet"
        fi
    done
    return 0
}

apply() {
    local src=$1
    src=$(realpath "$src")
    [[ -r $src ]] || {
        echo "background.sh: cannot read $src" >&2
        exit 1
    }
    identify "$src[0]" >/dev/null 2>&1 || {
        echo "background.sh: $src is not an image magick can read" >&2
        exit 1
    }
    command -v magick >/dev/null || {
        echo "background.sh: no magick (install imagemagick)" >&2
        exit 1
    }

    echo "From ${src/#"$HOME"/\~} ($(identify -format '%wx%h %m' "$src[0]"))"
    echo "Into ${themes/#"$HOME"/\~}: bg.jpg, bg.png, and bg-blur.{jpg,png} blurred $blur"
    if ((assume_yes == 0)); then
        local reply
        read -rp "Write them? [Y/n] " reply
        [[ -z $reply || $reply == [yY]* ]] || {
            echo "Left alone."
            exit 0
        }
    fi

    # Written through a temporary directory, so a magick that fails half way
    # leaves the backgrounds that are there in place and whole.
    local tmp
    tmp=$(mktemp -d)
    # The path is baked into the trap: tmp is local and the trap runs after it
    # has gone.
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp'" EXIT
    render "$src" "$tmp/bg.jpg" 0
    render "$src" "$tmp/bg.png" 0
    render "$src" "$tmp/bg-blur.jpg" 1
    render "$src" "$tmp/bg-blur.png" 1

    local name
    for name in bg.jpg bg.png bg-blur.jpg bg-blur.png; do
        cat "$tmp/$name" >"$themes/$name"
        printf '  %-12s %s\n' "$name" "$(identify -format '%wx%h  %b' "$themes/$name")"
    done

    reload_backgrounds
}

# ---------------------------------------------------------------------------
# Putting the new picture on screen. Every one of these is a no-op unless that
# program is running here, so the same script is right on any of the three
# desktops, and a reload that fails is never a write that failed: the files are
# on disk by the time any of this runs.
# ---------------------------------------------------------------------------

# sway spawns swaybg itself from the `bg` lines in its output blocks and starts
# it again on every reload, so asking sway is enough and the paths stay in one
# place. No exec_always in the config, so nothing else is started twice.
reload_sway() {
    [[ -n ${SWAYSOCK:-} ]] || return 0
    command -v swaymsg >/dev/null || return 0
    echo "  reload       sway"
    swaymsg -q reload || true
    return 0
}

# A swaybg nothing owns - niri spawns one at startup and never touches it
# again - is replaced by one started with the same argv, so the outputs and
# modes it was given survive. The new surface is up before the old one goes,
# which is what keeps the desktop from flashing black in between.
reload_swaybg() {
    local pid argv had=0
    command -v swaybg >/dev/null || return 0
    for pid in $(pgrep -x swaybg 2>/dev/null); do
        mapfile -d '' -t argv <"/proc/$pid/cmdline" 2>/dev/null || continue
        ((${#argv[@]})) || continue
        setsid "${argv[@]}" >/dev/null 2>&1 &
        sleep 0.3
        kill "$pid" 2>/dev/null || true
        had=1
    done
    ((had)) && echo "  reload       swaybg"
    return 0
}

# hyprpaper holds the picture in memory, so a file that changed underneath it is
# not enough - it has to be told to read the path again. That is one IPC call,
# and hyprctl answers "ok" when it lands.
#
# When it does not - an older hyprpaper, a renamed request - the daemon is
# started again with the argv it already had, which is what reload_swaybg does
# and is correct whatever the IPC happens to be called. The new instance is up
# before the old one goes, so the desktop does not flash.
reload_hyprpaper() {
    local bg=$themes/bg.jpg pid argv
    [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || return 0
    command -v hyprctl >/dev/null || return 0
    pgrep -x hyprpaper >/dev/null 2>&1 || return 0

    if [[ $(hyprctl hyprpaper reload ",$bg" 2>/dev/null) == ok* ]]; then
        echo "  reload       hyprpaper"
        return 0
    fi

    for pid in $(pgrep -x hyprpaper 2>/dev/null); do
        mapfile -d '' -t argv <"/proc/$pid/cmdline" 2>/dev/null || continue
        ((${#argv[@]})) || continue
        setsid "${argv[@]}" >/dev/null 2>&1 &
        sleep 0.3
        kill "$pid" 2>/dev/null || true
    done
    echo "  reload       hyprpaper (restart)"
    return 0
}

# X11: feh writes the root pixmap and exits, so there is no feh to signal - it
# is run again the way scripts/startup.sh runs it. Skipped under a compositor,
# where DISPLAY is Xwayland's and its root window is on no screen.
reload_feh() {
    [[ -n ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]] || return 0
    command -v feh >/dev/null || return 0
    echo "  reload       feh"
    feh --bg-scale "$themes/bg.jpg" >/dev/null 2>&1 || true
    return 0
}

reload_backgrounds() {
    ((do_reload)) || return 0
    echo
    if [[ -n ${SWAYSOCK:-} ]]; then
        reload_sway
    elif [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
        reload_hyprpaper
    else
        reload_swaybg
    fi
    reload_feh
}

case ${1:-} in
    __preview)
        preview "$2"
        exit 0
        ;;
    __view)
        view "$2"
        exit 0
        ;;
esac

while (($#)); do
    case $1 in
        -d | --dir) dir=${2:?--dir needs a directory}; shift ;;
        -b | --blur) blur=${2:?--blur needs a spec like 0x6}; shift ;;
        -q | --quality) quality=${2:?--quality needs a number}; shift ;;
        -y | --yes) assume_yes=1 ;;
        -n | --no-reload) do_reload=0 ;;
        --show) show; exit 0 ;;
        -h | --help) usage; exit 0 ;;
        -*) usage >&2; exit 2 ;;
        *) picture=$1 ;;
    esac
    shift
done

apply "${picture:-$(choose)}"
