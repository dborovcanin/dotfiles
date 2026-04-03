#!/usr/bin/env bash
set -euo pipefail

IMG="$(mktemp /tmp/lock-XXXXXX.png)"
BLUR="$(mktemp /tmp/lock-blur-XXXXXX.png)"

cleanup() {
    rm -f "$IMG" "$BLUR"
}
trap cleanup EXIT

swaymsg 'output * dpms on' >/dev/null 2>&1 || true
sleep 0.2

if grim "$IMG"; then
    if magick "$IMG" -filter Gaussian -blur 0x6 "$BLUR"; then
        exec swaylock -f -i "$BLUR"
    else
        exec swaylock -f -i "$IMG"
    fi
else
    exec swaylock -f -c 000000
fi