#!/bin/bash

BL=$(ls /sys/class/backlight | head -n1)
BASE="/sys/class/backlight/$BL"

MAX=$(cat $BASE/max_brightness)
CUR=$(cat $BASE/brightness)

STEP=$((MAX/20))   # 5% step

case "$1" in
    up)
        NEW=$((CUR+STEP))
        ;;
    down)
        NEW=$((CUR-STEP))
        ;;
esac

if [ "$NEW" -gt "$MAX" ]; then NEW=$MAX; fi
if [ "$NEW" -lt 1 ]; then NEW=1; fi

echo $NEW > $BASE/brightness
