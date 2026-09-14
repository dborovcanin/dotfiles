#!/usr/bin/env bash
# System menu, replacing sway's "$mode_system" binding mode.
set -euo pipefail

LOCKBG="$HOME/Downloads/bg-blur.jpg"
SCRIPTS="$HOME/dotfiles/config/niri/scripts"

choice="$(
    printf '%s\n' lock "travel lock" logout suspend reboot shutdown |
        rofi -dmenu -i -p system \
            -font 'JetBrainsMono Nerd Font 14' \
            -theme-str 'window {width: 20%;} listview {lines: 6;}'
)" || exit 0

case "$choice" in
    lock) swaylock -f --image "$LOCKBG" ;;
    "travel lock") "$SCRIPTS/travel_lock.sh" ;;
    logout) niri msg action quit --skip-confirmation ;;
    suspend) systemctl suspend ;;
    reboot) systemctl reboot ;;
    shutdown) systemctl poweroff ;;
esac
