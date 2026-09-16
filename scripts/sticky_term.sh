#!/usr/bin/env bash

# A floating terminal in the project directory, sized for the display it opens on.
# foot under sway, st under i3; the window rules in each config make it sticky.

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/wm.sh"

res=$(xrandr | grep '*' | awk '{ print $1 }')

cd ~/go/src/github.com/absmach/supermq

size="1200 700"
position="715 55"
case $res in
  "1920x1080") position="1010 60" size="900 550" ;;
  "1920x1200") position="715 55" size="1200 700" ;;
  "2560x1440") position="1250 55" size="1300 800" ;;
  "3440x1440") position="1630 65" size="1800 1000" ;;
esac

case $WM in
  i3)
    st -n "sticky_term" -A 0.7 &
    sleep 0.2
    i3-msg -q "[instance=\"sticky_term\"] resize set $size"
    i3-msg -q "[instance=\"sticky_term\"] move position $position"
    ;;
  *)
    footclient --app-id "sticky_term" &
    sleep 0.2
    swaymsg "[app_id=\"sticky_term\"] resize set $size" >/dev/null
    swaymsg "[app_id=\"sticky_term\"] move position $position" >/dev/null
    ;;
esac
