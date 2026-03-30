#!/usr/bin/env bash
set -e

IMG="/tmp/lock.png"

# Take screenshot
grim "$IMG"

# Blur it (fast + decent quality)
magick "$IMG" -filter Gaussian -blur 0x6 "$IMG"

# Lock
exec swaylock -f -i "$IMG"