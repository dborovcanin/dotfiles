#!/usr/bin/env bash
# Focus an urgent window, replacing sway's "[urgent=latest] focus".
#
# Niri does not record when a window became urgent, so of all urgent windows
# this picks the one focused most recently.
set -euo pipefail

id="$(
    niri msg --json windows | jq -r '
        [.[] | select(.is_urgent)]
        | sort_by(.focus_timestamp.secs // 0, .focus_timestamp.nanos // 0)
        | last
        | .id // empty'
)"

[ -n "$id" ] || exit 0
niri msg action focus-window --id "$id"
