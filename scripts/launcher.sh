#!/usr/bin/env bash
set -euo pipefail

# The application launcher, drawn by config/rofi/menu.rasi.
#
# Usage: launcher.sh [extra rofi arguments]
#
# LAUNCHER_TERMINAL is what runs applications that want a terminal; foot when
# it is not set.

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# nf-md-rocket_launch, spelled as a code point like the icons in power.sh.
icon=$'\U000F14DE'

exec rofi -show drun -show-icons -drun-display-format '{name}' \
    -display-drun "$icon" \
    -terminal "${LAUNCHER_TERMINAL:-foot}" \
    -theme "$here/../config/rofi/menu.rasi" \
    "$@"
