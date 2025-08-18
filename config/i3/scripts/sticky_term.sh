#!/bin/sh	

# Determine display size to set position and size of sticky terminal.
res=$(xrandr | grep '*' | awk '{ print $1 }')

cd ~/go/src/github.com/absmach/supermq
st -n "sticky_term" -A 0.7 &
# i3-msg -q exec "st -n 'sticky_term'"

# Wait for the window to open and grab its window ID
sleep 0.2
size="1200 700"
position="715 55"
echo $res

case $res in
  "1920x1080") position="1010 60" size="900 550" ;;
  "1920x1200") position="715 55" size="1200 700" ;;
  "2560x1440") position="1250 55" size="1300 800" ;;
  "3440x1440") position="1630 65" size="1800 1000" ;;
esac

i3-msg -q [instance="sticky_term"] resize set $size
i3-msg -q [instance="sticky_term"] move position $position
