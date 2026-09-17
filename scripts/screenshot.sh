#!/usr/bin/env bash
set -euo pipefail

# Select an area, annotate it, and copy the result to the clipboard.
#
# Wayland (sway, niri, hyprland): grim + slurp, annotated in satty, copied with
# wl-copy.
# X11 (i3): flameshot, copied with xclip, then focus goes back where it was.

if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
    # Save to tmp - it's on RAM.
    dir=/tmp/screenshots
    mkdir -p "$dir"
    tmp=$(mktemp "$dir/screenshot-XXXX.png")
    trap 'rm -f "$tmp"' EXIT

    grim -g "$(slurp)" "$tmp" || exit 1
    satty --actions-on-escape=save-to-file,exit -f "$tmp" -o "$tmp" || exit 1
    wl-copy <"$tmp"
else
    focused_win=$(xdotool getwindowfocus)
    tmp=$(mktemp --suffix=.png)

    cleanup() {
        rm -f "$tmp"
        # Refocus even if flameshot was cancelled or copy failed
        xdotool windowactivate "$focused_win" >/dev/null 2>&1 || true
    }
    trap cleanup EXIT

    # -r prints raw PNG to stdout; a cancelled capture leaves the file empty.
    if flameshot gui -r >"$tmp" && [[ -s $tmp ]]; then
        xclip -selection clipboard -t image/png -i "$tmp"
    fi
fi
