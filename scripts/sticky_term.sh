#!/usr/bin/env bash

# A floating terminal in the project directory, sized for the display it opens on.
# foot everywhere but i3, which gets st; the window rules in each config make it
# sticky. sway and hyprland are placed by hand here because both can be told where
# to put a window that is already up; niri and anything else are left to the size
# and placement their own window rules give.

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/wm.sh"

# The resolution of the monitor with the focus, as WIDTHxHEIGHT. hyprland is
# asked directly; everywhere else falls back to xrandr, which under Wayland
# answers for Xwayland rather than for the compositor.
screen_res() {
  local res=""
  if [ "$WM" = hyprland ] && command -v jq >/dev/null 2>&1; then
    res=$(hyprctl -j monitors 2>/dev/null |
      jq -r 'first(.[] | select(.focused)) | "\(.width)x\(.height)"' 2>/dev/null)
  fi
  # An empty or malformed answer falls through rather than sizing off nothing.
  case $res in
    [0-9]*x[0-9]*) printf '%s\n' "$res"; return 0 ;;
  esac
  xrandr 2>/dev/null | awk '/\*/ { print $1; exit }'
}

res=$(screen_res)

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
  hyprland)
    footclient --app-id "sticky_term" &
    sleep 0.2
    hyprctl dispatch resizewindowpixel "exact $size,class:^(sticky_term)$" >/dev/null
    hyprctl dispatch movewindowpixel "exact $position,class:^(sticky_term)$" >/dev/null
    ;;
  sway)
    footclient --app-id "sticky_term" &
    sleep 0.2
    swaymsg "[app_id=\"sticky_term\"] resize set $size" >/dev/null
    swaymsg "[app_id=\"sticky_term\"] move position $position" >/dev/null
    ;;
  *)
    footclient --app-id "sticky_term" &
    ;;
esac
