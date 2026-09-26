#!/usr/bin/env bash
set -euo pipefail

# The screen share picker, drawn by config/rofi/menu.rasi.
#
# xdg-desktop-portal-wlr runs this as its chooser (config/xdg-desktop-portal-wlr)
# whenever an app - OBS, a browser, a call - asks to capture the screen. The
# portal writes one source per line on stdin, "Monitor: <name> ..." or
# "Window: <title> (<app id>)", and reads the chosen line back from stdout,
# unchanged. Nothing printed means nothing is shared.

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# nf-md-monitor_share, nf-md-monitor and nf-md-application, spelled as code
# points like the icons in power.sh.
icon=$'\U000F1483'
i_monitor=$'\U000F0379'
i_window=$'\U000F08C6'

mapfile -t sources
((${#sources[@]})) || exit 1

# The rows lose the portal's "Monitor: " and "Window: " for an icon apiece;
# the row's index is what comes back, so the portal still gets its own line.
rows() {
    local line
    for line in "${sources[@]}"; do
        case $line in
            'Monitor: '*) printf '%s  %s\n' "$i_monitor" "${line#Monitor: }" ;;
            'Window: '*) printf '%s  %s\n' "$i_window" "${line#Window: }" ;;
            *) printf '%s\n' "$line" ;;
        esac
    done
}

choice=$(rows | rofi -dmenu -i -matching fuzzy -format i -no-custom \
    -p "$icon" \
    -theme "$here/../config/rofi/menu.rasi" \
    -theme-str 'window {width: 44em;}') || exit 1

[[ $choice =~ ^[0-9]+$ ]] && ((choice < ${#sources[@]})) || exit 1
printf '%s\n' "${sources[choice]}"
