#!/bin/sh

start_once() {
    app="$1"
    shift

    command -v "$app" >/dev/null 2>&1 || return 0
    if command -v pgrep >/dev/null 2>&1; then
        pgrep -x "$app" >/dev/null 2>&1 || "$app" "$@" >/dev/null 2>&1 &
    else
        "$app" "$@" >/dev/null 2>&1 &
    fi
}

# Under i3 (X11): turn the built-in monitor off when an external one is
# connected, and set the wallpaper. Sway, niri and hyprland do both in their configs.
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    if command -v xrandr >/dev/null 2>&1; then
        xr_state="$(xrandr --query 2>/dev/null || true)"

        if printf '%s\n' "$xr_state" | grep -Eq '^(DP|DisplayPort)-[^[:space:]]+[[:space:]]+connected'; then
            for internal in eDP-1 eDP1 eDP; do
                if printf '%s\n' "$xr_state" | grep -Eq "^${internal}[[:space:]]+connected"; then
                    xrandr --output "$internal" --off
                fi
            done
        fi
    fi

    wallpaper="$HOME/dotfiles/themes/bg.jpg"
    if [ -f "$wallpaper" ] && command -v feh >/dev/null 2>&1; then
        feh --bg-scale "$wallpaper" >/dev/null 2>&1 &
    fi
fi

start_once codium
start_once brave

# Start Slack only on workdays (Mon=1 ... Sun=7).
weekday="$(date '+%u')"
if [ "$weekday" -lt 6 ]; then
    sleep 3
    start_once slack
fi
